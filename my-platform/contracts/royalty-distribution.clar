;; Decentralized Content Monetization Platform - Royalty Distribution Contract
;; This contract enables multiple creators to collaborate on content and automatically
;; distribute revenue based on predefined royalty percentages with governance mechanisms

;; Error codes
(define-constant err-unauthorized (err u100))
(define-constant err-work-not-found (err u101))
(define-constant err-work-exists (err u102))
(define-constant err-invalid-collaborator (err u103))
(define-constant err-invalid-percentage (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-no-pending-revenue (err u106))
(define-constant err-already-voted (err u107))
(define-constant err-proposal-not-found (err u108))
(define-constant err-proposal-expired (err u109))
(define-constant err-proposal-not-passed (err u110))
(define-constant err-invalid-proposal (err u111))
(define-constant err-work-locked (err u112))

;; Constants
(define-constant contract-owner tx-sender)
(define-constant max-collaborators u10)
(define-constant voting-period u1440) ;; ~10 days in blocks
(define-constant min-vote-threshold u51) ;; 51% threshold for proposals

;; Data variables
(define-data-var work-counter uint u0)
(define-data-var proposal-counter uint u0)
(define-data-var platform-fee-percentage uint u250) ;; 2.5% platform fee

;; Work status
(define-constant work-status-active u1)
(define-constant work-status-locked u2) ;; Locked during governance updates

;; Proposal types
(define-constant proposal-type-royalty-update u1)
(define-constant proposal-type-add-collaborator u2)
(define-constant proposal-type-remove-collaborator u3)

;; Proposal status
(define-constant proposal-status-active u1)
(define-constant proposal-status-passed u2)
(define-constant proposal-status-rejected u3)
(define-constant proposal-status-executed u4)

;; Collaborative work structure
(define-map collaborative-works
  uint ;; work-id
  {
    title: (string-ascii 100),
    creator: principal,
    total-collaborators: uint,
    total-revenue: uint,
    status: uint,
    created-at: uint,
    governance-enabled: bool
  }
)

;; Collaborator royalty percentages
(define-map royalty-shares
  { work-id: uint, collaborator: principal }
  { 
    percentage: uint, ;; Out of 10000 (100.00%)
    is-dynamic: bool,
    total-earned: uint,
    last-withdrawal: uint
  }
)

;; Work collaborators list
(define-map work-collaborators
  uint ;; work-id
  (list 10 principal)
)

;; Revenue tracking per work
(define-map work-revenue
  uint ;; work-id
  {
    total-received: uint,
    total-distributed: uint,
    pending-distribution: uint,
    last-distribution: uint
  }
)

;; Governance proposals
(define-map proposals
  uint ;; proposal-id
  {
    work-id: uint,
    proposer: principal,
    proposal-type: uint,
    target-collaborator: (optional principal),
    new-percentage: (optional uint),
    description: (string-ascii 200),
    votes-for: uint,
    votes-against: uint,
    total-eligible-voters: uint,
    created-at: uint,
    expires-at: uint,
    status: uint
  }
)

;; Voting records
(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, voted-at: uint }
)

;; Private functions

;; Check if caller is work creator
(define-private (is-work-creator (work-id uint))
  (let ((work (unwrap! (map-get? collaborative-works work-id) false)))
    (is-eq tx-sender (get creator work))
  )
)

;; Check if caller is collaborator
(define-private (is-collaborator (work-id uint) (collaborator principal))
  (is-some (map-get? royalty-shares { work-id: work-id, collaborator: collaborator }))
)

;; Calculate individual payout amount
(define-private (calculate-payout (amount uint) (percentage uint))
  (/ (* amount percentage) u10000)
)

;; Check if proposal has passed
(define-private (has-proposal-passed (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) false)))
    (let ((votes-for (get votes-for proposal))
          (total-voters (get total-eligible-voters proposal)))
      (>= (* votes-for u100) (* total-voters min-vote-threshold))
    )
  )
)

;; Public functions

;; Create a new collaborative work
(define-public (create-collaborative-work 
                (title (string-ascii 100))
                (collaborators (list 10 principal))
                (percentages (list 10 uint))
                (governance-enabled bool))
  (let ((work-id (+ (var-get work-counter) u1))
        (current-block stacks-block-height))
    
    ;; Validate inputs
    (asserts! (> (len title) u0) err-invalid-proposal)
    (asserts! (is-eq (len collaborators) (len percentages)) err-invalid-percentage)
    (asserts! (<= (len collaborators) max-collaborators) err-invalid-collaborator)
    (asserts! (> (len collaborators) u0) err-invalid-collaborator)
    
    ;; Validate percentages sum to 100%
    (let ((total-percentage (fold + percentages u0)))
      (asserts! (is-eq total-percentage u10000) err-invalid-percentage)
    )
    
    ;; Create work
    (map-set collaborative-works work-id {
      title: title,
      creator: tx-sender,
      total-collaborators: (len collaborators),
      total-revenue: u0,
      status: work-status-active,
      created-at: current-block,
      governance-enabled: governance-enabled
    })
    
    ;; Set collaborators
    (map-set work-collaborators work-id collaborators)
    
    ;; Set initial royalty shares
    (try! (setup-royalty-shares work-id collaborators percentages))
    
    ;; Initialize revenue tracking
    (map-set work-revenue work-id {
      total-received: u0,
      total-distributed: u0,
      pending-distribution: u0,
      last-distribution: current-block
    })
    
    ;; Increment counter
    (var-set work-counter work-id)
    
    (ok work-id))
)

;; Helper function to set up royalty shares
(define-private (setup-royalty-shares 
                 (work-id uint) 
                 (collaborators (list 10 principal)) 
                 (percentages (list 10 uint)))
  (let ((current-block stacks-block-height)
        (pairs (map create-pair collaborators percentages)))
    (fold setup-single-share pairs (ok work-id))
  )
)

;; Helper function to set up a single royalty share
(define-private (setup-single-share 
                 (pair { collaborator: principal, percentage: uint }) 
                 (acc (response uint uint)))
  (if (is-ok acc)
      (let ((work-id (unwrap-panic acc)))
        (map-set royalty-shares 
          { work-id: work-id, collaborator: (get collaborator pair) }
          {
            percentage: (get percentage pair),
            is-dynamic: false,
            total-earned: u0,
            last-withdrawal: stacks-block-height
          })
        (ok work-id))
      acc)
)

;; Helper function to create pairs
(define-private (create-pair (collaborator principal) (percentage uint))
  { collaborator: collaborator, percentage: percentage }
)

;; Receive payment for a collaborative work
(define-public (receive-payment (work-id uint) (amount uint))
  (let ((work (unwrap! (map-get? collaborative-works work-id) err-work-not-found))
        (current-revenue (default-to 
          { total-received: u0, total-distributed: u0, pending-distribution: u0, last-distribution: u0 }
          (map-get? work-revenue work-id))))
    
    ;; Ensure work is active
    (asserts! (is-eq (get status work) work-status-active) err-work-locked)
    (asserts! (> amount u0) err-invalid-percentage)
    
    ;; Transfer payment to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Calculate platform fee
    (let ((platform-fee (/ (* amount (var-get platform-fee-percentage)) u10000))
          (net-amount (- amount platform-fee)))
      
      ;; Update work revenue
      (map-set work-revenue work-id {
        total-received: (+ (get total-received current-revenue) amount),
        total-distributed: (get total-distributed current-revenue),
        pending-distribution: (+ (get pending-distribution current-revenue) net-amount),
        last-distribution: (get last-distribution current-revenue)
      })
      
      ;; Update work total revenue
      (map-set collaborative-works work-id 
        (merge work { total-revenue: (+ (get total-revenue work) amount) }))
      
      (ok net-amount))
  )
)

;; Distribute pending revenue to all collaborators
(define-public (distribute-revenue (work-id uint))
  (let ((work (unwrap! (map-get? collaborative-works work-id) err-work-not-found))
        (revenue (unwrap! (map-get? work-revenue work-id) err-no-pending-revenue))
        (collaborators (unwrap! (map-get? work-collaborators work-id) err-work-not-found)))
    
    ;; Check if there's pending revenue
    (asserts! (> (get pending-distribution revenue) u0) err-no-pending-revenue)
    
    ;; Distribute to each collaborator
    (try! (distribute-to-collaborators work-id collaborators (get pending-distribution revenue)))
    
    ;; Update revenue tracking
    (map-set work-revenue work-id {
      total-received: (get total-received revenue),
      total-distributed: (+ (get total-distributed revenue) (get pending-distribution revenue)),
      pending-distribution: u0,
      last-distribution: stacks-block-height
    })
    
    (ok (get pending-distribution revenue))
  )
)

;; Helper function to distribute to all collaborators
(define-private (distribute-to-collaborators 
                 (work-id uint) 
                 (collaborators (list 10 principal)) 
                 (total-amount uint))
  (fold distribute-to-single-collaborator 
        collaborators 
        (ok { work-id: work-id, amount: total-amount }))
)

;; Helper function to distribute to a single collaborator
(define-private (distribute-to-single-collaborator 
                 (collaborator principal) 
                 (acc (response { work-id: uint, amount: uint } uint)))
  (if (is-ok acc)
      (let ((data (unwrap-panic acc))
            (work-id (get work-id data))
            (total-amount (get amount data)))
        (let ((share-opt (map-get? royalty-shares { work-id: work-id, collaborator: collaborator })))
          (if (is-some share-opt)
              (let ((share (unwrap-panic share-opt))
                    (payout (calculate-payout total-amount (get percentage share))))
                ;; Transfer payout
                (match (as-contract (stx-transfer? payout tx-sender collaborator))
                  success (begin
                    ;; Update collaborator's earnings
                    (map-set royalty-shares { work-id: work-id, collaborator: collaborator }
                      (merge share { 
                        total-earned: (+ (get total-earned share) payout),
                        last-withdrawal: stacks-block-height 
                      }))
                    (ok data))
                  error acc))
              acc)))
      acc)
)

;; Create governance proposal
(define-public (create-proposal 
                (work-id uint)
                (proposal-type uint)
                (target-collaborator (optional principal))
                (new-percentage (optional uint))
                (description (string-ascii 200)))
  (let ((work (unwrap! (map-get? collaborative-works work-id) err-work-not-found))
        (proposal-id (+ (var-get proposal-counter) u1))
        (current-block stacks-block-height))
    
    ;; Ensure governance is enabled
    (asserts! (get governance-enabled work) err-unauthorized)
    
    ;; Ensure caller is a collaborator
    (asserts! (is-collaborator work-id tx-sender) err-unauthorized)
    
    ;; Validate proposal type
    (asserts! (or (is-eq proposal-type proposal-type-royalty-update)
                 (is-eq proposal-type proposal-type-add-collaborator)
                 (is-eq proposal-type proposal-type-remove-collaborator))
             err-invalid-proposal)
    
    ;; Create proposal
    (map-set proposals proposal-id {
      work-id: work-id,
      proposer: tx-sender,
      proposal-type: proposal-type,
      target-collaborator: target-collaborator,
      new-percentage: new-percentage,
      description: description,
      votes-for: u0,
      votes-against: u0,
      total-eligible-voters: (get total-collaborators work),
      created-at: current-block,
      expires-at: (+ current-block voting-period),
      status: proposal-status-active
    })
    
    ;; Increment counter
    (var-set proposal-counter proposal-id)
    
    (ok proposal-id))
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
        (current-block stacks-block-height))
    
    ;; Check if proposal is still active
    (asserts! (is-eq (get status proposal) proposal-status-active) err-proposal-expired)
    (asserts! (<= current-block (get expires-at proposal)) err-proposal-expired)
    
    ;; Check if caller is eligible to vote
    (asserts! (is-collaborator (get work-id proposal) tx-sender) err-unauthorized)
    
    ;; Check if already voted
    (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) err-already-voted)
    
    ;; Record vote
    (map-set votes { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote-for, voted-at: current-block })
    
    ;; Update proposal vote counts
    (map-set proposals proposal-id
      (merge proposal {
        votes-for: (if vote-for (+ (get votes-for proposal) u1) (get votes-for proposal)),
        votes-against: (if vote-for (get votes-against proposal) (+ (get votes-against proposal) u1))
      }))
    
    (ok true))
)

;; Execute passed proposal
(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
        (current-block stacks-block-height))
    
    ;; Check if proposal has passed
    (asserts! (has-proposal-passed proposal-id) err-proposal-not-passed)
    
    ;; Check if proposal hasn't expired
    (asserts! (<= current-block (get expires-at proposal)) err-proposal-expired)
    
    ;; Execute based on proposal type - FIXED: Both branches return (response bool uint)
    (let ((execution-result 
           (if (is-eq (get proposal-type proposal) proposal-type-royalty-update)
               (execute-royalty-update proposal)
               (ok true)))) ;; Both branches now return same type
      
      (try! execution-result)
      
      ;; Mark proposal as executed
      (map-set proposals proposal-id
        (merge proposal { status: proposal-status-executed }))
      
      (ok true))
  )
)

;; Helper function to execute royalty update - FIXED: Returns (response bool uint)
(define-private (execute-royalty-update (proposal { work-id: uint, proposer: principal, proposal-type: uint, target-collaborator: (optional principal), new-percentage: (optional uint), description: (string-ascii 200), votes-for: uint, votes-against: uint, total-eligible-voters: uint, created-at: uint, expires-at: uint, status: uint }))
  (let ((work-id (get work-id proposal))
        (target (unwrap! (get target-collaborator proposal) err-invalid-proposal))
        (new-pct (unwrap! (get new-percentage proposal) err-invalid-proposal)))
    
    ;; Validate new percentage
    (asserts! (and (> new-pct u0) (<= new-pct u10000)) err-invalid-percentage)
    
    ;; Update royalty share
    (let ((current-share (unwrap! (map-get? royalty-shares { work-id: work-id, collaborator: target }) err-invalid-collaborator)))
      (map-set royalty-shares { work-id: work-id, collaborator: target }
        (merge current-share { percentage: new-pct }))
      
      (ok true))
  )
)

;; Read-only functions

;; Get collaborative work details
(define-read-only (get-work (work-id uint))
  (map-get? collaborative-works work-id)
)

;; Get collaborator's royalty share
(define-read-only (get-royalty-share (work-id uint) (collaborator principal))
  (map-get? royalty-shares { work-id: work-id, collaborator: collaborator })
)

;; Get work revenue details
(define-read-only (get-work-revenue (work-id uint))
  (map-get? work-revenue work-id)
)

;; Get work collaborators
(define-read-only (get-work-collaborators (work-id uint))
  (map-get? work-collaborators work-id)
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Get vote details
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

;; Get platform fee percentage
(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage)
)

;; Get work counter
(define-read-only (get-work-counter)
  (var-get work-counter)
)

;; Get proposal counter
(define-read-only (get-proposal-counter)
  (var-get proposal-counter)
)

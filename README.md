# Decentralized Content Monetization Platform

A blockchain-based platform that enables multiple creators to collaborate on content and automatically distribute revenue based on predefined royalty percentages, with built-in governance mechanisms for managing collaborative works.

## Overview

This platform solves the complex problem of revenue sharing among multiple content creators by providing transparent, automated, and trustless distribution of payments. Whether you're working on music, art, writing, or any other collaborative creative work, this smart contract ensures fair and automatic compensation for all contributors.

## Key Features

### 🤝 Collaborative Work Management
- Create collaborative works with multiple contributors
- Define fixed or dynamic royalty percentages for each collaborator
- Support for up to 10 collaborators per work
- Transparent tracking of all revenue and distributions

### 💰 Automatic Revenue Distribution
- Automatic splitting of incoming payments based on predefined percentages
- Real-time revenue tracking and distribution
- Platform fee management (2.5% default)
- Individual withdrawal tracking for each collaborator

### 🗳️ Decentralized Governance
- Multisig-style voting for royalty updates
- Proposal system for adding/removing collaborators
- 51% threshold for proposal approval
- Time-limited voting periods (~10 days)

### 🔒 Security & Transparency
- Immutable royalty agreements once set
- All transactions and distributions are publicly verifiable
- Built-in safeguards against unauthorized changes
- Governance locks during proposal execution

## Smart Contract Architecture

### Core Data Structures

#### Collaborative Works
Each work contains:
- Title and creator information
- List of collaborators and their royalty percentages
- Revenue tracking (total received, distributed, pending)
- Governance settings and status

#### Royalty Shares
For each collaborator:
- Percentage allocation (out of 10,000 for precision)
- Dynamic vs. fixed percentage flag
- Total earnings and withdrawal history
- Last withdrawal timestamp

#### Governance Proposals
- Proposal types: royalty updates, add/remove collaborators
- Voting mechanism with for/against tallies
- Time-limited voting periods
- Execution tracking

## Usage Examples

### Creating a Collaborative Work

\`\`\`clarity
;; Create a music collaboration with 3 artists
(create-collaborative-work 
  "Summer Hit 2024"
  (list 'SP1... 'SP2... 'SP3...)  ;; Collaborator addresses
  (list u4000 u3500 u2500)        ;; 40%, 35%, 25% respectively
  true)                           ;; Enable governance
\`\`\`

### Receiving Payments

\`\`\`clarity
;; Fan purchases the song for 100 STX
(receive-payment u1 u100000000) ;; work-id: 1, amount: 100 STX
\`\`\`

### Distributing Revenue

\`\`\`clarity
;; Distribute accumulated revenue to all collaborators
(distribute-revenue u1) ;; work-id: 1
\`\`\`

### Governance Proposals

\`\`\`clarity
;; Propose to update a collaborator's royalty percentage
(create-proposal 
  u1                              ;; work-id
  u1                              ;; proposal-type: royalty-update
  (some 'SP1...)                  ;; target collaborator
  (some u4500)                    ;; new percentage: 45%
  "Increase Alice's share for additional vocals")
\`\`\`

## Revenue Distribution Flow

1. **Payment Reception**: Fans/buyers send STX to purchase or support content
2. **Platform Fee Deduction**: 2.5% platform fee is automatically deducted
3. **Revenue Accumulation**: Net revenue accumulates in the work's pending distribution pool
4. **Distribution Trigger**: Any collaborator can trigger distribution of pending revenue
5. **Automatic Splitting**: Smart contract automatically calculates and sends each collaborator's share
6. **Tracking Update**: Individual earnings and withdrawal records are updated

## Governance Process

1. **Proposal Creation**: Any collaborator can create proposals for changes
2. **Voting Period**: ~10 days for all collaborators to vote
3. **Threshold Check**: Proposals need 51% approval to pass
4. **Execution**: Passed proposals can be executed by any collaborator
5. **Implementation**: Changes take effect immediately upon execution

## Security Considerations

- **Percentage Validation**: Total royalty percentages must equal exactly 100%
- **Access Control**: Only collaborators can vote, only creators can add initial collaborators
- **Governance Locks**: Works are locked during active governance proposals
- **Time Limits**: Proposals expire after voting period to prevent stale governance
- **Immutable History**: All revenue and distribution history is permanently recorded

## Platform Economics

- **Platform Fee**: 2.5% of all revenue (adjustable by contract owner)
- **Gas Optimization**: Batch operations for multiple collaborators
- **Scalability**: Designed to handle high-volume content monetization

## Development Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) v2.0+
- [Stacks CLI](https://github.com/blockstack/stacks.js)

### Installation

\`\`\`bash
# Clone the repository
git clone https://github.com/your-username/decentralized-content-monetization.git

# Navigate to project directory
cd decentralized-content-monetization

# Install dependencies
clarinet install

# Run tests
clarinet test
\`\`\`

### Testing

\`\`\`bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/royalty-distribution_test.ts

# Check contract syntax
clarinet check
\`\`\`

### Deployment

\`\`\`bash
# Deploy to testnet
clarinet deploy --testnet

# Deploy to mainnet
clarinet deploy --mainnet
\`\`\`

## API Reference

### Public Functions

#### Work Management
- \`create-collaborative-work\`: Create a new collaborative work
- \`receive-payment\`: Process incoming revenue
- \`distribute-revenue\`: Distribute pending revenue to collaborators

#### Governance
- \`create-proposal\`: Create governance proposals
- \`vote-on-proposal\`: Vote on active proposals  
- \`execute-proposal\`: Execute passed proposals

### Read-Only Functions

#### Data Retrieval
- \`get-work\`: Get collaborative work details
- \`get-royalty-share\`: Get collaborator's royalty information
- \`get-work-revenue\`: Get revenue tracking details
- \`get-work-collaborators\`: Get list of collaborators
- \`get-proposal\`: Get proposal details
- \`get-vote\`: Get voting records

## Use Cases

### Music Industry
- **Band Revenue Sharing**: Automatically split streaming revenue, concert earnings, and merchandise sales
- **Producer Collaborations**: Fair compensation for producers, songwriters, and performers
- **Label Partnerships**: Transparent revenue sharing between artists and labels

### Digital Art & NFTs
- **Collaborative Art Projects**: Multiple artists working on single pieces
- **Collection Royalties**: Ongoing royalty distribution for NFT collections
- **Community Art**: Revenue sharing for community-driven art projects

### Content Creation
- **YouTube Collaborations**: Revenue sharing for collaborative videos
- **Podcast Networks**: Automatic distribution for multi-host podcasts
- **Writing Collaborations**: Fair compensation for co-authored books or articles

### Gaming & Development
- **Indie Game Development**: Revenue sharing among developers, artists, and musicians
- **Mod Development**: Compensation for game modification creators
- **Asset Creation**: Revenue sharing for game asset collaborations

## Roadmap

### Phase 1: Core Functionality ✅
- Basic royalty distribution
- Collaborative work creation
- Simple governance

### Phase 2: Enhanced Governance 🚧
- Advanced proposal types
- Weighted voting based on contribution
- Emergency governance mechanisms

### Phase 3: Integration & Scaling 📋
- Cross-chain compatibility
- Integration with content platforms
- Advanced analytics and reporting

### Phase 4: Advanced Features 📋
- Dynamic royalty adjustments based on performance
- Escrow mechanisms for disputed works
- Integration with legal frameworks

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Process
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [docs.example.com](https://docs.example.com)
- **Discord**: [Join our community](https://discord.gg/example)
- **Issues**: [GitHub Issues](https://github.com/your-username/decentralized-content-monetization/issues)

## Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Clarinet team for development tools
- Open source contributors and community feedback

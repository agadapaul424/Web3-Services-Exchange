# P2P Service Marketplace

A decentralized peer-to-peer service marketplace built on the Stacks blockchain using Clarity smart contracts. This platform enables users to offer and book services with secure escrow payments, built-in reviews, and trustless transactions.

## 🌟 Features

### Core Functionality
- **User Profiles**: Create and manage professional profiles with skills, bio, and verification status
- **Service Listings**: Post services with categories, pricing, and availability
- **Secure Booking System**: Multi-stage booking process with confirmation and completion workflows
- **Escrow Payments**: Automatic payment holding until service completion
- **Review System**: Post-completion ratings and reviews (1-5 stars)
- **Category Management**: Organized service categories for easy discovery

### Security Features
- **Authorization Checks**: Role-based access control for all operations
- **Payment Security**: STX tokens held in smart contract escrow
- **Dispute Resolution**: Emergency functions for platform governance
- **Input Validation**: Comprehensive error handling and data validation

## 🏗️ Architecture

### Smart Contract Structure
```
contracts/
└── p2p-marketplace.clar    # Main marketplace contract
```

### Key Data Structures
- **Services**: Service listings with pricing and metadata
- **Bookings**: Booking records with status tracking
- **User Profiles**: User information and reputation data
- **Reviews**: Rating and feedback system
- **Escrow**: Secure payment holding mechanism

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v16+) - For running tests
- [Stacks Wallet](https://www.hiro.so/wallet) - For interacting with the contract

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd p2p-service-marketplace
   ```

2. **Install Clarinet**
   ```bash
   # macOS
   brew install clarinet
   
   # Or download from GitHub releases
   # https://github.com/hirosystems/clarinet/releases
   ```

3. **Initialize Clarinet project**
   ```bash
   clarinet new marketplace
   cd marketplace
   ```

4. **Add the contract**
   ```bash
   # Copy the contract code to contracts/p2p-marketplace.clar
   ```

5. **Install test dependencies**
   ```bash
   npm install vitest
   ```

### Deployment

1. **Check contract syntax**
   ```bash
   clarinet check
   ```

2. **Run tests**
   ```bash
   clarinet test
   # or
   npm test
   ```

3. **Deploy to testnet**
   ```bash
   clarinet deploy --testnet
   ```

## 📖 Usage Guide

### For Service Providers

1. **Create Profile**
   ```clarity
   (contract-call? .p2p-marketplace create-profile 
     "John Developer" 
     "Full-stack developer with 5 years experience" 
     "JavaScript, React, Node.js, Python")
   ```

2. **List a Service**
   ```clarity
   (contract-call? .p2p-marketplace create-service
     "Web Development Service"
     "I will build your website using modern technologies"
     "web-development"
     u50  ;; $50 per hour
     "USD"
     "Monday-Friday, 9AM-5PM")
   ```

3. **Manage Bookings**
   ```clarity
   ;; Confirm booking
   (contract-call? .p2p-marketplace confirm-booking u1)
   
   ;; Mark as completed
   (contract-call? .p2p-marketplace complete-booking u1)
   ```

### For Service Buyers

1. **Browse and Book Services**
   ```clarity
   ;; View service details
   (contract-call? .p2p-marketplace get-service u1)
   
   ;; Book service
   (contract-call? .p2p-marketplace book-service 
     u1  ;; service-id
     u3  ;; hours
     u1640995200)  ;; scheduled timestamp
   ```

2. **Complete Transaction**
   ```clarity
   ;; Release payment after service completion
   (contract-call? .p2p-marketplace release-payment u1)
   
   ;; Add review
   (contract-call? .p2p-marketplace add-review 
     u1  ;; booking-id
     u5  ;; rating (1-5)
     "Excellent service, highly recommended!")
   ```

## 🔧 API Reference

### User Management
- `create-profile(name, bio, skills)` - Create user profile
- `update-profile(name, bio, skills)` - Update existing profile
- `get-user-profile(user)` - Retrieve user profile

### Service Management
- `create-service(title, description, category, price, currency, availability)` - List new service
- `update-service(service-id, title, description, price, availability, status)` - Update service
- `get-service(service-id)` - Get service details

### Booking System
- `book-service(service-id, hours, scheduled-time)` - Book a service
- `confirm-booking(booking-id)` - Confirm booking (provider only)
- `complete-booking(booking-id)` - Mark booking complete (provider only)
- `cancel-booking(booking-id)` - Cancel booking
- `release-payment(booking-id)` - Release escrowed payment (client only)
- `get-booking(booking-id)` - Get booking details

### Review System
- `add-review(booking-id, rating, comment)` - Add review after completion
- `get-review(booking-id, reviewer)` - Get specific review

### Platform Management
- `add-category(category)` - Add service category (owner only)
- `update-platform-fee(new-fee)` - Update platform fee (owner only)
- `verify-user(user)` - Verify user account (owner only)

## 💰 Economics

### Fee Structure
- **Platform Fee**: 2.5% of transaction value (250 basis points)
- **Payment Method**: STX tokens
- **Escrow**: Automatic holding until service completion

### Service Categories
- Web Development
- Graphic Design
- Writing & Content
- Business Consulting
- Tutoring & Education
- Photography
- Digital Marketing
- Music & Audio

## 🧪 Testing

The project includes comprehensive unit tests using Vitest:

```bash
# Run all tests
npm test

# Run specific test file
npm test marketplace.test.js

# Run tests in watch mode
npm test -- --watch
```

### Test Coverage
- ✅ User profile management
- ✅ Service creation and updates
- ✅ Booking workflow (create → confirm → complete)
- ✅ Payment escrow system
- ✅ Review and rating system
- ✅ Error handling and edge cases
- ✅ Authorization and security checks

## 🔒 Security Considerations

### Smart Contract Security
- **No External Dependencies**: Pure Clarity implementation
- **Input Validation**: All parameters validated before processing
- **Authorization Checks**: Function-level access control
- **State Management**: Careful handling of contract state transitions

### Payment Security
- **Escrow System**: Funds held securely until service completion
- **Atomic Transactions**: All-or-nothing payment releases
- **Fee Transparency**: Clear platform fee calculations

### Best Practices
- **Test Coverage**: Comprehensive test suite for all functionality
- **Error Handling**: Graceful handling of edge cases
- **Documentation**: Clear function documentation and usage examples

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Clarity best practices
- Add tests for new functionality
- Update documentation as needed
- Ensure all tests pass before submitting

## 📋 Project Structure

```
p2p-service-marketplace/
├── contracts/
│   └── p2p-marketplace.clar     # Main smart contract
├── tests/
│   └── marketplace.test.js      # Unit tests
├── Clarinet.toml               # Clarinet configuration
├── package.json                # Node.js dependencies
└── README.md                   # This file
```

## 🚧 Roadmap

### Phase 1 (Current)
- ✅ Core marketplace functionality
- ✅ Escrow payment system
- ✅ Review system
- ✅ Comprehensive testing

### Phase 2 (Planned)
- [ ] Advanced search and filtering
- [ ] Dispute resolution system
- [ ] Multi-token support
- [ ] Mobile-friendly interface

### Phase 3 (Future)
- [ ] Integration with other DeFi protocols
- [ ] Advanced reputation algorithms
- [ ] Bulk operations support
- [ ] Analytics dashboard

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check this README and inline code comments
- **Issues**: Report bugs via GitHub Issues
- **Community**: Join our [Discord](https://discord.gg/stacks) for discussions
- **Email**: Contact us at support@marketplace.example

## 🏆 Acknowledgments

- Built on [Stacks blockchain](https://www.stacks.co/)
- Powered by [Clarity smart contracts](https://clarity-lang.org/)
- Developed with [Clarinet](https://github.com/hirosystems/clarinet)
- Tested with [Vitest](https://vitest.dev/)

---

**⚠️ Disclaimer**: This is experimental software. Use at your own risk. Always test thoroughly before deploying to mainnet.
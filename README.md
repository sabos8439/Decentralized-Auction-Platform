# 🎯 Decentralized Auction Platform

A blockchain-based auction platform built with Clarity smart contracts on Stacks. Create auctions, place bids, and manage time-based bidding logic in a completely decentralized manner.

## ✨ Features

- 🏷️ **Create Auctions**: Set up auctions with custom items, descriptions, starting bids, reserve prices, and durations
- 💰 **Place Bids**: Bid on active auctions with automatic outbid handling
- ⏰ **Time-Based Logic**: Auctions automatically end after specified block duration
- 🔄 **Automatic Refunds**: Previous bidders are automatically refunded when outbid
- 🏆 **Winner Selection**: Highest bidder wins when auction ends (if reserve price is met)
- 💎 **Reserve Price Protection**: Sellers can set minimum acceptable prices for their items
- 🛡️ **Security Features**: Prevents self-bidding and invalid operations
- 🚨 **Emergency Controls**: Sellers can emergency-end their auctions

## 🚀 Quick Start

### Prerequisites
- [Clarinet CLI](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <your-repo>
cd Decentralized-Auction-Platform
clarinet check
```

## 📖 Usage Guide

### Creating an Auction

```clarity
(contract-call? .decentralized-auction-platform create-auction 
  "Vintage Guitar" 
  "1965 Fender Stratocaster in excellent condition"
  u1000000   ;; 1 STX starting bid
  u2500000   ;; 2.5 STX reserve price (minimum to win)
  u1000)     ;; 1000 blocks duration
```

### Placing a Bid

```clarity
(contract-call? .decentralized-auction-platform place-bid 
  u1          ;; auction ID
  u1500000)   ;; 1.5 STX bid
```

### Finalizing an Auction

```clarity
(contract-call? .decentralized-auction-platform finalize-auction u1)
```

## 🔍 Read-Only Functions

### Get Auction Details
```clarity
(contract-call? .decentralized-auction-platform get-auction-details u1)
```

### Check Auction Status
```clarity
(contract-call? .decentralized-auction-platform get-auction-status u1)
```

### Get Time Remaining
```clarity
(contract-call? .decentralized-auction-platform get-time-remaining u1)
```

### Get Winning Bid
```clarity
(contract-call? .decentralized-auction-platform get-winning-bid u1)
```

### Check Reserve Price Status
```clarity
(contract-call? .decentralized-auction-platform reserve-price-met u1)
```

## ⚡ Key Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-auction` | Create a new auction | item-name, description, starting-bid, reserve-price, duration |
| `place-bid` | Place a bid on active auction | auction-id, bid-amount |
| `finalize-auction` | End auction and transfer funds | auction-id |
| `emergency-end-auction` | Seller emergency stop | auction-id |
| `get-auction-details` | View auction information | auction-id |
| `get-auction-status` | Check if auction is active | auction-id |
| `reserve-price-met` | Check if current bid meets reserve | auction-id |

## 🏗️ Contract Architecture

### Data Structures

- **Auctions Map**: Stores auction details, bids, and timing
- **Bids Map**: Tracks individual bid history
- **User Bids Map**: Maps users to their auction bids

### Key Features

- **Reserve Price Logic**: Auctions only succeed if final bid meets minimum price
- **Automatic Refunds**: Previous highest bidders are instantly refunded
- **Smart Finalization**: Winners only pay if reserve is met, otherwise refunded
- **Time Validation**: Bids rejected after auction end block
- **Anti-Manipulation**: Prevents sellers from bidding on own auctions
- **State Management**: Tracks auction lifecycle and finalization

## 🛡️ Security Features

- ✅ Prevents self-bidding
- ✅ Validates auction timing
- ✅ Ensures bid amounts are sufficient
- ✅ Protects against double-spending
- ✅ Automatic escrow handling

## 🧪 Testing

```bash
clarinet test
```

Run specific test file:
```bash
clarinet test tests/auction_test.ts
```

## 📊 Error Codes

| Code | Description |
|------|-------------|
| u100 | Not authorized |
| u101 | Auction not found |
| u102 | Auction ended |
| u103 | Auction active |
| u104 | Bid too low |
| u105 | Invalid duration |
| u106 | Invalid starting bid |
| u107 | Self-bid attempt |
| u108 | No bids placed |
| u109 | Already finalized |
| u110 | Auction not ended |
| u111 | Reserve price not met |

## 🔮 Future Enhancements

- 🏪 Multi-item auctions
- 📈 Reserve price functionality  
- 🎁 Auction extensions
- 📱 Frontend integration
- 🔔 Event notifications

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🙋‍♂️ Support

Need help? Open an issue or contact the development team.

---

*Built with ❤️ using Clarity and Stacks blockchain*

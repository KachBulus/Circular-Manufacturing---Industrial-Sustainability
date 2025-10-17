## 🌍 Overview

A blockchain-based solution for tracking industrial product lifecycles, managing waste, and incentivizing sustainable recycling practices through tokenized rewards.

## ✨ Features

- 📱 **Digital Product Passports** - Complete lifecycle tracking for industrial products
- 📊 **Waste Management** - Real-time waste generation and tracking
- ♻️ **Recycling Verification** - Verified recycling with automatic token rewards
- 🏆 **Manufacturer Quotas** - Enforce recycling quotas and sustainability goals
- 🔌 **IoT Integration** - Connect sensors for automated data collection
- 💰 **EcoToken Rewards** - Incentivize sustainable practices
- 📦 **Product Batch Management** - Group and manage related products efficiently

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation
```bash
git clone <repository-url>
cd Circular-Manufacturing---Industrial-Sustainability
clarinet check
```

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy --testnet
```

## 📖 Usage

### Register a Product
```clarity
(contract-call? .circular-manufacturing register-product "Steel Beam A1" "steel" u1000)
```

### Track Product Lifecycle
```clarity
(contract-call? .circular-manufacturing update-product-lifecycle u1 "in-use" "Factory Floor B")
```

### Register Waste
```clarity
(contract-call? .circular-manufacturing register-waste u1 "metal-scraps" u250 "Warehouse C")
```

### Verify Recycling
```clarity
(contract-call? .circular-manufacturing verify-recycling u1 "mechanical" u85)
```

### Register IoT Sensor
```clarity
(contract-call? .circular-manufacturing register-iot-sensor "SENSOR001" "Production Line 1" "weight")
```

### Submit Sensor Data
```clarity
(contract-call? .circular-manufacturing submit-sensor-data "SENSOR001" u1 "weight: 950kg")
```

## 📋 Contract Functions

### 🔍 Read-Only Functions
- `get-product(product-id)` - Get product details
- `get-waste-record(waste-id)` - Get waste record
- `get-recycling-event(recycling-id)` - Get recycling event details
- `get-manufacturer-quota(manufacturer)` - Get recycling quota status
- `get-user-balance(user)` - Get EcoToken balance

### ✏️ Public Functions
- `register-product(name, material-type, weight)` - Create digital passport
- `update-product-lifecycle(product-id, new-stage, location)` - Update lifecycle stage
- `register-waste(product-id, waste-type, quantity, location)` - Log waste generation
- `verify-recycling(waste-id, method, efficiency)` - Verify and reward recycling
- `register-iot-sensor(sensor-id, location, sensor-type)` - Add IoT sensor
- `submit-sensor-data(sensor-id, product-id, data)` - Submit sensor readings
- `transfer-tokens(recipient, amount)` - Transfer EcoTokens
- `create-product-batch(product-ids, batch-size)` - Group products into batches
- `update-batch-status(batch-id, new-status)` - Update batch lifecycle status

## 🏗️ Architecture

### Data Structures
- **Products** - Digital passports with lifecycle tracking
- **Waste Records** - Waste generation and disposal tracking
- **Recycling Events** - Verified recycling activities with rewards
- **Manufacturer Quotas** - Sustainability targets and compliance
- **IoT Sensors** - Sensor registration and data collection
- **Product Batches** - Grouped product collections for bulk operations

### Token Economy
- **EcoTokens** - Fungible tokens rewarded for verified recycling
- **Reward Rate** - Configurable reward multiplier based on efficiency
- **Balance Tracking** - User token balance management

## 📊 Error Codes

| Code | Description |
|------|-------------|
| u100 | Unauthorized access |
| u101 | Resource not found |
| u102 | Resource already exists |
| u103 | Invalid amount |
| u104 | Insufficient balance |
| u105 | Invalid status |

## 🔒 Security Features

- ✅ Owner-only administrative functions
- ✅ Product manufacturer verification
- ✅ IoT sensor ownership validation
- ✅ Balance checks for token transfers
- ✅ Status validation for state transitions

## 🌱 Sustainability Impact

- **Waste Reduction** - Track and minimize industrial waste
- **Recycling Incentives** - Reward sustainable practices
- **Compliance Monitoring** - Enforce recycling quotas
- **Transparency** - Full lifecycle visibility
- **Efficiency** - Automated IoT data collection
- **Batch Operations** - Streamlined management of product groups

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality  
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

For questions and support, please open an issue on GitHub.

---

*Building a sustainable future, one product at a time* 🌿

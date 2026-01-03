# Token Vault Upgradeable - UUPS Proxy Pattern Implementation

## Overview

This project demonstrates a production-grade smart contract system implementing the UUPS (Universal Upgradeable Proxy Standard) proxy pattern for managing an upgradeable token vault across multiple versions (V1, V2, and V3). The system showcases best practices in smart contract security, state management across upgrades, and comprehensive testing strategies.

## Project Structure

```
token-vault-upgradeable/
├── contracts/
│   ├── TokenVaultV1.sol        # Initial vault implementation with basic deposit/withdrawal
│   ├── TokenVaultV2.sol        # Enhanced version with yield tracking
│   ├── TokenVaultV3.sol        # Production version with withdrawal delays
│   ├── TokenVaultProxy.sol     # UUPS Proxy contract
│   ├── MockERC20.sol           # Test token implementation
│   └── interfaces/
│       └── ITokenVault.sol        # Vault interface definitions
├── test/
│   ├── TokenVault.test.js      # Comprehensive test suite
│   └── fixtures/              # Test fixtures and setup
├── hardhat.config.js         # Hardhat configuration
├── package.json             # Project dependencies
└── README.md                # This file
```

## Key Features

### V1 - Basic Token Vault
- Deposit tokens into the vault
- Withdraw tokens (with balance checks)
- Track user balances
- Role-based access control (admin, upgrader)

### V2 - Yield Tracking
- All V1 features plus:
- Yield accumulation based on holding period
- Yield claim functionality with double-claiming prevention
- Timestamp-based yield calculation
- Storage gap pattern for safe upgrades

### V3 - Production Grade
- All V2 features plus:
- Withdrawal delays for security
- Emergency withdrawal mechanism
- Rate limiting on withdrawals
- Comprehensive pause/unpause functionality
- Multi-sig support for critical operations

## Smart Contract Architecture

### UUPS Proxy Pattern
This project uses the Universal Upgradeable Proxy Standard (UUPS) instead of the Transparent Proxy pattern for the following reasons:

1. **Smaller Proxy Bytecode**: Reduces deployment costs
2. **Explicit Upgrade Control**: Upgrade logic is in the implementation contract, providing better security
3. **Gas Efficiency**: Lower gas costs for function calls
4. **Flexibility**: Allows complex upgrade patterns and validation

### Storage Layout & Gas Optimization

#### Storage Layout Strategy
- Reserved storage gaps (uint256[50] __gap) to allow future state variable additions
- Storage gap calculation: `remaining_gap = original_gap - newly_added_variables`
- Prevents storage collision attacks during upgrades

#### Gas Optimizations Implemented
- Used uint256 for frequently accessed variables, uint8/uint16 for less critical values
- Batch processing for multiple operations
- Mappings instead of arrays where order isn't required
- Events instead of storage for historical data
- Memory caching of storage values within functions
- Fast-fail require statements
- Assembly for gas-critical overflow checks

### Access Control Architecture

Role-Based Access Control (RBAC) using OpenZeppelin's AccessControl:

```solidity
DEFAULT_ADMIN_ROLE        // Manages all roles
UPGRADER_ROLE             // Executes contract upgrades
MINTER_ROLE               // Mints new tokens
BURNER_ROLE               // Burns tokens
WITHDRAWAL_OPERATOR_ROLE  // Handles withdrawal delays and emergency withdrawals
```

### Security Measures

#### Initialization Security
- Initializer modifier prevents multiple initialization calls
- DisableInitializers in constructor prevents implementation contract attacks
- Access control on initialize function with role checks
- Initialization state verification before critical operations

#### Upgrade Safety
- Storage layout validation ensures compatibility
- Function signature verification tests
- Comprehensive test coverage for state persistence across upgrades
- Time-lock mechanism for upgrades
- Initialization guards during upgrades

#### Reentrancy Protection
- Checks-Effects-Interactions (CEI) pattern throughout
- State updates before external calls
- ReentrancyGuard for critical functions

#### Additional Protections
- SafeMath for overflow/underflow prevention
- Zero-address validation
- Rate limiting on sensitive operations
- Emergency pause functionality

## Installation & Setup

### Prerequisites
- Node.js >= 14.0.0
- npm >= 6.0.0
- Hardhat

### Installation

```bash
# Clone the repository
git clone https://github.com/manikantaoruganti/token-vault-upgradeable.git
cd token-vault-upgradeable

# Install dependencies
npm install

# Compile contracts
npx hardhat compile
```

## Testing

The project includes comprehensive tests covering normal operations, edge cases, and upgrade scenarios.

```bash
# Run all tests
npx hardhat test

# Run tests with gas reporting
GAS_REPORTER=true npx hardhat test

# Run specific test file
npx hardhat test test/TokenVault.test.js

# Run tests with coverage
npx hardhat coverage
```

### Test Coverage
- Unit tests for individual functions
- Integration tests for component interactions
- Upgrade tests ensuring state persistence
- Access control validation tests
- Edge case tests (zero balances, maximum values, rapid operations)
- Negative tests for proper error handling
- Time-dependent tests using Hardhat's time manipulation
- Stress tests with concurrent operations
- Gas measurement tests

**Target Coverage**: >90% line coverage with focus on critical paths

## Deployment

### Development Network

```bash
# Start Hardhat network
npx hardhat node

# In another terminal, deploy
npx hardhat run scripts/deploy.js --network localhost
```

### Testnet Deployment (Sepolia)

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export SEPOLIA_RPC_URL=your_rpc_url

# Deploy to Sepolia
npx hardhat run scripts/deploy.js --network sepolia
```

### Production Deployment Recommendations

Before mainnet deployment, implement:

1. **Professional Audit**: Get a reputable firm (OpenZeppelin, Trail of Bits) to audit the code
2. **Formal Verification**: For critical upgrade and state migration functions
3. **Multi-Signature**: Implement multi-sig for all admin functions with time-locks
4. **Testnet Period**: Deploy on Sepolia with public review period
5. **Circuit Breakers**: Implement pause mechanisms and emergency withdrawal functionality
6. **Monitoring**: Set up comprehensive alerting for anomalous behavior
7. **Progressive Rollout**: Start with limited TVL, gradually increase as confidence grows
8. **Bug Bounty**: Establish a bug bounty program
9. **Incident Response**: Create clear escalation procedures

## Usage Example

```solidity
// Deploy the vault
const vault = await TokenVault.deploy();

// Initialize with token and yield rate
await vault.initialize(tokenAddress, ethers.parseEther("0.01")); // 1% daily yield

// Deposit tokens
const depositAmount = ethers.parseEther("100");
await token.approve(vault.address, depositAmount);
await vault.deposit(depositAmount);

// Check balance
const balance = await vault.balanceOf(userAddress);
console.log("Balance:", ethers.formatEther(balance));

// Claim yield (V2+)
await vault.claimYield();

// Request withdrawal (V3) with delay
await vault.requestWithdrawal(ethers.parseEther("50"));

// Wait for withdrawal delay (configured value)
await time.increase(7 * 24 * 60 * 60); // 7 days

// Complete withdrawal
await vault.completeWithdrawal();
```

## Upgrade Process

### From V1 to V2

```javascript
const V2Implementation = await ethers.getContractFactory("TokenVaultV2");
const v2Impl = await V2Implementation.deploy();
await vault.upgradeTo(v2Impl.address);
```

### From V2 to V3

With state migration:

```javascript
const V3Implementation = await ethers.getContractFactory("TokenVaultV3");
const v3Impl = await V3Implementation.deploy();
await vault.upgradeToAndCall(v3Impl.address, migrateDataSelector);
```

## Storage Layout

### V1 Storage
```solidity
uint256 totalDeposits;
mapping(address => uint256) userBalances;
uint256[50] __gap;
```

### V2 Storage (Consumes part of gap)
```solidity
uint256 totalDeposits;          // V1
mapping(address => uint256) userBalances; // V1

uint256 yieldRate;              // V2
mapping(address => uint256) lastYieldClaim; // V2
mapping(address => uint256) lastYieldAmount; // V2
uint256[47] __gap;              // Remaining gap
```

### V3 Storage (Further consumes gap)
```solidity
// V1 + V2 fields

uint256 withdrawalDelay;        // V3
mapping(address => uint256) withdrawalRequestTime; // V3
mapping(address => uint256) withdrawalAmount; // V3
uint256 maxWithdrawalPerDay;    // V3
uint256[44] __gap;              // Remaining gap
```

## Gas Optimization Strategies

1. **Efficient Storage Packing**: Group variables by size to minimize storage slots
2. **Batch Operations**: Process multiple items in single transaction
3. **Smart Data Structures**: Use mappings over arrays where applicable
4. **Memory Optimization**: Cache frequently accessed storage values in memory
5. **Event Logging**: Use events for historical data instead of storage
6. **Fail-Fast Logic**: Order require statements by probability of failure
7. **Assembly Usage**: For gas-critical mathematical operations

## Common Issues & Troubleshooting

### Issue: "Implementation contract must implement upgradeTo"
**Solution**: Ensure all implementation contracts inherit from UUPSUpgradeable

### Issue: "Storage collision during upgrade"
**Solution**: Verify storage gap calculations and use reserved gap array

### Issue: "Function not found after upgrade"
**Solution**: Check function signatures haven't changed, verify proxy points to new implementation

### Issue: "State lost after upgrade"
**Solution**: Use `delegatecall` pattern in proxy, verify initialization guards

## Performance Considerations

- **Gas Costs**: UUPS proxy has lower call overhead than Transparent Proxy
- **Storage**: Each upgrade can be optimized for specific use cases
- **Deployment**: Smaller bytecode means lower deployment costs
- **Execution**: Function calls have minimal overhead (single delegatecall)

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security Considerations

This is an educational project demonstrating best practices. Before using in production:

- Get a professional audit
- Implement formal verification
- Test extensively on testnet
- Use multi-signature wallets for upgrades
- Implement comprehensive monitoring
- Have incident response procedures in place

## License

This project is licensed under the MIT License - see LICENSE file for details.

## References

- [OpenZeppelin UUPS Pattern](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable)
- [Solidity Docs](https://docs.soliditylang.org/)
- [EIP-1822: UUPS](https://eips.ethereum.org/EIPS/eip-1822)
- [Hardhat Documentation](https://hardhat.org/docs)

## Authors

- **Manikanta Venkateswarlu Oruganti** - Initial implementation and upgrades

## Support

For issues and questions:
- Open an GitHub issue
- Check existing issues for solutions
- Review test files for usage examples

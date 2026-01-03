// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenVaultV1
 * @dev Upgradeable smart contract for token deposit/withdrawal with deposit fees
 */
contract TokenVaultV1 is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    IERC20 public token;
    uint256 public depositFee;
    
    // Storage for user balances
    mapping(address => uint256) public userBalances;
    uint256 public totalDeposits;
    
    // Storage gaps for future versions
    uint256[50] private __gap;
    
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    
    event Deposited(address indexed user, uint256 amount, uint256 fee);
    event Withdrawn(address indexed user, uint256 amount);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @dev Initialize the contract with token, admin, and deposit fee
     */
    function initialize(address _token, address _admin, uint256 _depositFee) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        require(_token != address(0), "Invalid token address");
        require(_admin != address(0), "Invalid admin address");
        require(_depositFee <= 10000, "Fee too high");
        
        token = IERC20(_token);
        depositFee = _depositFee;
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);
    }
    
    /**
     * @dev Deposit tokens into the vault
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Calculate fee (fee is in basis points: 500 = 5%)
        uint256 fee = (amount * depositFee) / 10000;
        uint256 userAmount = amount - fee;
        
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        userBalances[msg.sender] += userAmount;
        totalDeposits += userAmount;
        
        emit Deposited(msg.sender, userAmount, fee);
    }
    
    /**
     * @dev Withdraw tokens from the vault
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(userBalances[msg.sender] >= amount, "Insufficient balance");
        
        userBalances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Get user balance
     */
    function balanceOf(address user) external view returns (uint256) {
        return userBalances[user];
    }
    
    /**
     * @dev Get total deposits
     */
    function totalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
    
    /**
     * @dev Get deposit fee
     */
    function getDepositFee() external view returns (uint256) {
        return depositFee;
    }
    
    /**
     * @dev Get implementation version
     */
    function getImplementationVersion() external pure returns (string memory) {
        return "V1";
    }
    
    /**
     * @dev Authorize upgrade
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVaultV2 is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    IERC20 public token;
    uint256 public depositFee;
    uint256 public yieldRate;
    bool public depositsPaused;
    
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userYieldClaimed;
    mapping(address => uint256) public lastYieldClaimTime;
    uint256 public totalDeposits;
    
    uint256[46] private __gap;
    
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    event Deposited(address indexed user, uint256 amount, uint256 fee);
    event Withdrawn(address indexed user, uint256 amount);
    event YieldClaimed(address indexed user, uint256 amount);
    event YieldRateSet(uint256 newRate);
    event DepositsPaused();
    event DepositsUnpaused();
    
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address _token, address _admin, uint256 _depositFee) external reinitializer(2) {
        require(_token != address(0), "Invalid token address");
        require(_admin != address(0), "Invalid admin address");
        require(_depositFee <= 10000, "Fee too high");
        
        token = IERC20(_token);
        depositFee = _depositFee;
        yieldRate = 0;
        depositsPaused = false;
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
    }
    
    function deposit(uint256 amount) external {
        require(!depositsPaused, "Deposits are paused");
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 fee = (amount * depositFee) / 10000;
        uint256 userAmount = amount - fee;
        
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        userBalances[msg.sender] += userAmount;
        totalDeposits += userAmount;
        
        if (lastYieldClaimTime[msg.sender] == 0) {
            lastYieldClaimTime[msg.sender] = block.timestamp;
        }
        
        emit Deposited(msg.sender, userAmount, fee);
    }
    
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(userBalances[msg.sender] >= amount, "Insufficient balance");
        
        userBalances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function setYieldRate(uint256 _yieldRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_yieldRate <= 10000, "Yield rate too high");
        yieldRate = _yieldRate;
        emit YieldRateSet(_yieldRate);
    }
    
    function getYieldRate() external view returns (uint256) {
        return yieldRate;
    }
    
    function getUserYield(address user) external view returns (uint256) {
        if (lastYieldClaimTime[user] == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - lastYieldClaimTime[user];
        uint256 yield = (userBalances[user] * yieldRate * timeElapsed) / (365 days * 10000);
        return yield;
    }
    
    function claimYield() external returns (uint256) {
        require(lastYieldClaimTime[msg.sender] > 0, "No deposits");
        
        uint256 timeElapsed = block.timestamp - lastYieldClaimTime[msg.sender];
        uint256 yield = (userBalances[msg.sender] * yieldRate * timeElapsed) / (365 days * 10000);
        
        require(yield > 0, "No yield to claim");
        
        lastYieldClaimTime[msg.sender] = block.timestamp;
        userYieldClaimed[msg.sender] += yield;
        
        require(token.transfer(msg.sender, yield), "Yield transfer failed");
        
        emit YieldClaimed(msg.sender, yield);
        return yield;
    }
    
    function pauseDeposits() external onlyRole(PAUSER_ROLE) {
        depositsPaused = true;
        emit DepositsPaused();
    }
    
    function unpauseDeposits() external onlyRole(PAUSER_ROLE) {
        depositsPaused = false;
        emit DepositsUnpaused();
    }
    
    function isDepositsPaused() external view returns (bool) {
        return depositsPaused;
    }
    
    function balanceOf(address user) external view returns (uint256) {
        return userBalances[user];
    }
    
    function totalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
    
    function getDepositFee() external view returns (uint256) {
        return depositFee;
    }
    
    function getImplementationVersion() external pure returns (string memory) {
        return "V2";
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}

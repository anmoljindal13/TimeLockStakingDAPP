// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "./DessertERC20.sol";

/**
 * @title Staking Contract
 * @dev Allows users to stake a deposit token for a given time lock and earn rewards in a custom ERC20 token named DESSERT.
 */
contract StakingContract {

    uint256 private constant SECONDS_IN_A_YEAR = 3.154e7;

    uint256 public interestRate;

    IERC20 public depositToken;
    ERC20 public returnToken;

    struct Stake {
        uint256 amount; 
        uint256 startTime;
        uint256 endTime;
        uint256 lastClaimTime;
    }

    mapping(address => Stake) private stakes;
    mapping(address => uint256) private existingStakeRewards;

    event RewardTokenCreation(address indexed createdBy, string name, string symbol, address createdAt);
    event ExistingStakeBrokenForRegisteringNewStake(address indexed user, uint256 amount);
    event DepositStake(address indexed user, uint256 amount, uint256 duration);
    event ClaimedReward(address indexed user, uint256 amount);
    event WithdrawalOfAllStakeAndReward(address indexed user, uint256 totalStakes, uint256 totalReturns);
    
    /**
     * @dev Constructor to initialize the interest rate, deposit token and return token.
     * Return Token Smart Contract is deployed as part of the constructor, which is owned by this smart contract.
     * @param _interestRate The interest rate for staking.
     * @param _depositToken The address of the deposit token.
     */
    constructor(uint256 _interestRate, address _depositToken) {
        interestRate = _interestRate;
        depositToken = IERC20(_depositToken);
        returnToken = new DESSERT();
        emit RewardTokenCreation(address(this), returnToken.name(), returnToken.symbol(), address(returnToken));
    }
    
    /**
     * @dev Allows a user to create a new stake.
     * @param amount The amount of deposit token to be staked.
     * @param duration The duration for which the stake will be locked.
     */
    function createDeposit(uint256 amount, uint256 duration) external {

        require(amount > 0, "Amount must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");
        require(depositToken.transferFrom(msg.sender, address(this), amount), "Deposit token transfer failed!");
        require(returnToken.approve(address(this), amount), "DESSERT spending approval failed!");
        uint256 existingStake = getUserStakeAmount(msg.sender);
        if(existingStake > 0) {
            amount += existingStake;
            existingStakeRewards[msg.sender] = checkAvailableReturns(msg.sender);
            console.log("Existing Stake will be broken to create a new effective stake amount for User "
                        "with wallet address : %s", msg.sender);
            emit ExistingStakeBrokenForRegisteringNewStake(msg.sender, existingStake);
        }
        Stake memory newStake = Stake(amount, block.timestamp, block.timestamp + duration, block.timestamp);
        stakes[msg.sender] = newStake;
        console.log("New Deposit created for : %s Deposit Token with lock of %s seconds for User with wallet address : %s",
                    amount, duration, msg.sender);
        emit DepositStake(msg.sender, amount, duration);
    }
        
    /**
    * @notice Allows a user to claim their returns from their stakes
    * @param user The address of the user claiming returns
    * @dev Calculates the returns for each stake that has ended and transfers the appropriate amount to the user.
    * Updates the lastClaimTime for each stake that has ended.
    * Emits the Claim event for each stake that has ended.
    * Throws an error if no returns are available to claim.
    */
    function claimReturns(address user) external {
        require(msg.sender == user, "Only the Owner of the Wallet is eligible to withdraw!");
        Stake storage stake = stakes[user];
        require(block.timestamp >= stake.endTime, "Lock Duration for the Claiming the DESSERT has not expired!");
   
        uint256 _returns = checkAvailableReturns(user);
        require(_returns > 0, "No returns available");
        stake.lastClaimTime = block.timestamp;
        
        require(returnToken.transfer(user, _returns), "DESSERT Claim failed!");
        existingStakeRewards[user] = 0;
        console.log("User with wallet address %s claimed return of %s %s", user, _returns, returnToken.symbol());
        emit ClaimedReward(user, _returns);

    }

    /**
    * @notice Allows a user to claim their returns from their stakes, as well as their invested stake.
    * @param user The address of the user claiming returns
    * @dev Calculates the returns for each stake that has ended and transfers the appropriate amount to the user.
    * Updates the lastClaimTime for each stake that has ended.
    * Emits the Claim event for each stake that has ended.
    * Throws an error if no returns are available to claim.
    */
    function withdrawAllStakeAndRewards(address user) external {
        require(msg.sender == user, "Only the Owner of the Wallet is eligible to withdraw! ");
        Stake storage stake = stakes[user];
        uint256 userStakedAmount = getUserStakeAmount(user);

        require(userStakedAmount > 0, "No stakes to withdraw");
        require(block.timestamp >= stake.endTime, "Lock Duration for Withdrawal has not expired! ");
        require(depositToken.transfer(user, userStakedAmount), "Stake Withdrawal failed!");
        console.log("User with wallet address %s unstaked their staked amount of %s deposit token", user, userStakedAmount);

        uint256 _returns = checkAvailableReturns(user);
        if(_returns > 0) {
            require(returnToken.transfer(user, _returns), "DESSERT Withdrawal failed!");
            existingStakeRewards[user] = 0;
            console.log("User with wallet address %s claimed return of %s %s", user, _returns, returnToken.symbol());
        }
        
        stake.amount = 0;
        stake.startTime = 0;
        stake.endTime = 0;
        stake.lastClaimTime = 0;
        
        emit WithdrawalOfAllStakeAndReward(user, userStakedAmount, _returns);
    }

    /**
    * @notice Returns an array of all stakes for a user
    * @param user The address of the user to retrieve stakes for
    * @return An array of all stakes for the user
    */
    function getUserStakeDetails(address user) external view returns(Stake memory) {
        return stakes[user];
    }

    /**
    * @notice Returns the total amount that the user has staked, involving various stakes
    * @param user The address of the user to retrieve the total stakes for
    * @return The total amount of stakes for the user
    */
    function getUserStakeAmount(address user) public view returns(uint256) {
        return stakes[user].amount;
    }

    /**
    * @notice Returns the total available returns for a user
    * @param user The address of the user to retrieve the total available returns
    * @return The total available returns for the user
    */
    function checkAvailableReturns(address user) public view returns(uint256) {
        uint256 totalReturns = existingStakeRewards[user];
        Stake storage userStake = stakes[user];

        if(block.timestamp >= userStake.endTime) {
            totalReturns += (userStake.amount * interestRate * (block.timestamp - userStake.lastClaimTime)) / (SECONDS_IN_A_YEAR);
        }
        
        return totalReturns;
    }

    /**
    * @notice Returns the total amount of DESSERT claimed by a user
    * @param user The address of the user to retrieve the total claimed DESSERT for
    * @return The total amount of DESSERT claimed by the user
    */
    function checkClaimedDessert(address user) external view returns (uint256) {
        return returnToken.balanceOf(user);
    }
}
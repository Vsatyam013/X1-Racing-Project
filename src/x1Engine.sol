// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {x1Coin} from "./x1Coin.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/**
 * @title x1Engine
 * @author Satyam Verma
 */

contract x1Engine is ReentrancyGuard {
    //////////////////
    ///// Errors ///// 
    //////////////////
    error x1Engine__NeedsMoreThanZero();
    error x1Engine__StakePeriodNotCompleted();
    error x1Engine__InsufficientStakedBalance();
    error x1Engine__InsufficientContractBalance();
    error x1Engine__ExceedsPublicAllocation();
    error x1Engine__ExceedsTeamAllocation();
    error x1Engine__ExceedsCommunityAllocation();
    error x1Engine__TokensLocked();
    error x1Engine__NotAuthorized();
    error x1Engine__StaleTokensTransferFailed();
    error x1Engine__InsufficientFunds();


    //////////////////
    ///// Events ///// 
    //////////////////
    event TokensMinted(address indexed to, uint256 amount);
    event TokensStaked(address indexed user, uint256 amount, uint256 timestamp);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 rewards, uint256 timestamp);
    event TeamTokensUnlocked(uint256 amount);

    //////////////////////
    ///// Constants ///// 
    //////////////////////
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    uint256 public constant PUBLIC_ALLOCATION = (TOTAL_SUPPLY * 50) / 100; // 50%
    uint256 public constant TEAM_ALLOCATION = (TOTAL_SUPPLY * 30) / 100; // 30%
    uint256 public constant COMMUNITY_ALLOCATION = (TOTAL_SUPPLY * 20) / 100; // 20%

    uint256 public constant REWARD_RATE = 10; // 10% annual reward
    uint256 public constant MINIMUM_STAKING_PERIOD = 30 days; // Minimum staking period

    /////////////////////////
    ///// State Variables /// 
    /////////////////////////
    uint256 public totalPublicMinted;
    uint256 public totalTeamMinted;
    uint256 public totalCommunityMinted;

    uint256 public totalStaked;
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public stakingStartTimes;

    uint256 public immutable teamUnlockTime;

    x1Coin public immutable x1Token;

    ///////////////////////
    ///// Modifiers ///// 
    ///////////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert x1Engine__NeedsMoreThanZero();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != x1Token.owner()) {
            revert x1Engine__NotAuthorized();
        }
        _;
    }

    ////////////////////////
    ///// Constructor ///// 
    ////////////////////////
    constructor(address x1CoinAddress) {
        x1Token = x1Coin(x1CoinAddress);
        teamUnlockTime = block.timestamp + 180 days; // Lock Team & Advisors allocation for 6 months
    }

    //////////////////////
    ///// Minting ///// 
    //////////////////////

    // Public Sale Minting
    function mintPublicTokens(address to, uint256 amount)
        external
        moreThanZero(amount)
        nonReentrant
    {
        if (totalPublicMinted + amount > PUBLIC_ALLOCATION) {
            revert x1Engine__ExceedsPublicAllocation();
        }
        totalPublicMinted += amount;
        x1Token.mint(to, amount);
        emit TokensMinted(to, amount);
    }

    // Team & Advisors Minting
    function mintTeamTokens(address to, uint256 amount)
        external
        moreThanZero(amount)
        nonReentrant
    {
        if (block.timestamp < teamUnlockTime) {
            revert x1Engine__TokensLocked();
        }
        if (totalTeamMinted + amount > TEAM_ALLOCATION) {
            revert x1Engine__ExceedsTeamAllocation();
        }
        totalTeamMinted += amount;
        x1Token.mint(to, amount);
        emit TokensMinted(to, amount);
    }

    // Community Development Minting
    function mintCommunityTokens(address to, uint256 amount)
        external
        moreThanZero(amount)
        nonReentrant
    {
        if (totalCommunityMinted + amount > COMMUNITY_ALLOCATION) {
            revert x1Engine__ExceedsCommunityAllocation();
        }
        totalCommunityMinted += amount;
        x1Token.mint(to, amount);
        emit TokensMinted(to, amount);
    }

    //////////////////////
    ///// Staking ///// 
    //////////////////////

    // Stake Tokens
    function stakeTokens(uint256 amount)
        external
        moreThanZero(amount)
        nonReentrant
    {
        // Transfer tokens from the user to the contract
        bool success = x1Token.transferFrom(msg.sender, address(this), amount);
        if(!success){
            revert x1Engine__StaleTokensTransferFailed();
        }

        // Update staking data
        stakedBalances[msg.sender] += amount;
        if (stakingStartTimes[msg.sender] == 0) {
            stakingStartTimes[msg.sender] = block.timestamp;
        }

        totalStaked += amount;
        emit TokensStaked(msg.sender, amount, block.timestamp);
    }

    // Unstake Tokens
    function unstakeTokens() external nonReentrant {
        uint256 stakedAmount = stakedBalances[msg.sender];
        if (stakedAmount == 0) {
            revert x1Engine__InsufficientStakedBalance();
        }

        uint256 stakingDuration = block.timestamp - stakingStartTimes[msg.sender];
        if (stakingDuration < MINIMUM_STAKING_PERIOD) {
            revert x1Engine__StakePeriodNotCompleted();
        }

        // Calculate rewards
        uint256 rewards = calculateRewards(msg.sender);

        // Reset staking data
        stakedBalances[msg.sender] = 0;
        stakingStartTimes[msg.sender] = 0;

        // Transfer staked tokens + rewards back to the user
        uint256 totalAmount = stakedAmount + rewards;
        if (x1Token.balanceOf(address(this)) < totalAmount) {
            revert x1Engine__InsufficientContractBalance();
        }

        x1Token.transfer(msg.sender, totalAmount);
        totalStaked -= stakedAmount;
        emit TokensUnstaked(msg.sender, stakedAmount, rewards, block.timestamp);
    }

    // Calculate Rewards
    function calculateRewards(address staker) public view returns (uint256) {
        uint256 stakedAmount = stakedBalances[staker];
        uint256 stakingDuration = block.timestamp - stakingStartTimes[staker];
        uint256 annualReward = (stakedAmount * REWARD_RATE) / 100;
        uint256 rewards = 0;
        if(stakingDuration>=365 days){
            rewards = (annualReward * stakingDuration)/(365 days);
        }
        return rewards;
    }

    

   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployX1Coin} from "../script/DeployX1Coin.s.sol";
import {x1Coin} from "../src/x1Coin.sol";
import {x1Engine} from "../src/x1Engine.sol";
import {console} from "forge-std/console.sol";

contract x1EngineTest is Test {
    DeployX1Coin deployer;
    x1Coin x1c;
    x1Engine x1e;
    
    address public USER = makeAddr("user");
    address public TEAM_MEMBER = makeAddr("team_member");

    address public OWNER;

    function setUp() public {
        deployer = new DeployX1Coin();
        (x1c, x1e) = deployer.run();
        OWNER = x1c.owner(); 
    }

    function testConstructorInitialSupply() public {
        uint256 expectedSupply = 1_000_000_000 * 10**18; // 1 billion tokens
        uint256 actualSupply = x1c.totalSupply();
        assertEq(actualSupply, expectedSupply, "Total supply should be 1 billion tokens");
    }

    function testMintPublicTokens() public {
        vm.prank(OWNER);
        x1e.mintPublicTokens(USER, 1000 ether);

        assertEq(x1c.balanceOf(USER), 1000 ether);
    }

    function testTeamMintFailsIfExceedsAllocation() public {
    uint256 excessiveAmount = 310_000_000 ether; // 310 million tokens (exceeds 300 million allocation)

    // Move time forward by 6 months to unlock team tokens
    vm.warp(block.timestamp + 180 days);

    vm.prank(OWNER);
    vm.expectRevert(x1Engine.x1Engine__ExceedsTeamAllocation.selector);
    x1e.mintTeamTokens(TEAM_MEMBER, excessiveAmount);
    }

    function testPublicMintFailsIfExceedsAllocation() public {
    uint256 excessiveAmount = 510_000_000 ether; // 510 million tokens (exceeds 500 million allocation)

    vm.prank(OWNER);
    vm.expectRevert(x1Engine.x1Engine__ExceedsPublicAllocation.selector);
    x1e.mintPublicTokens(USER, excessiveAmount);
    }

    function testCommunityMintFailsIfExceedsAllocation() public {
    uint256 excessiveAmount = 210_000_000 ether; // 210 million tokens (exceeds 200 million allocation)

    vm.prank(OWNER);
    vm.expectRevert(x1Engine.x1Engine__ExceedsCommunityAllocation.selector);
    x1e.mintCommunityTokens(USER, excessiveAmount);
    }

     function testOnlyOwnerCanMintTeamAndCommunityTokens() public {
        vm.prank(USER);
        vm.expectRevert(x1Engine.x1Engine__NotAuthorized.selector);
        x1e.mintTeamTokens(USER, 1000 ether);
        
        vm.prank(USER);
        vm.expectRevert(x1Engine.x1Engine__NotAuthorized.selector);
        x1e.mintCommunityTokens(USER, 1000 ether);
    }

    function testTeamCannotMintBeforeLockPeriod() public {
    uint256 unlockTime = x1e.teamUnlockTime(); // Read the lock time from contract
    assertGt(unlockTime, block.timestamp);

    vm.prank(OWNER);
    vm.expectRevert(x1Engine.x1Engine__TokensLocked.selector);
    x1e.mintTeamTokens(TEAM_MEMBER, 1000 ether);
    }

    function testTeamCanMintAfterLockPeriod() public {
        vm.warp(block.timestamp + 180 days); // Move time forward past lock period

        vm.prank(OWNER);
        x1e.mintTeamTokens(TEAM_MEMBER, 1000 ether);

        assertEq(x1c.balanceOf(TEAM_MEMBER), 1000 ether);
    }

    function testUnstakeTokensFailsIfNoStake() public {
    // Ensure USER has not staked anything
    assertEq(x1e.stakedBalances(USER), 0);

    // Expect revert due to insufficient staked balance
    vm.prank(USER);
    vm.expectRevert(x1Engine.x1Engine__InsufficientStakedBalance.selector);
    x1e.unstakeTokens();
    }

    function testUnstakeTokensFailsIfStakingPeriodNotCompleted() public {
    uint256 stakeAmount = 1000 ether;

    // Mint tokens to user and approve staking contract
    vm.prank(OWNER);
    x1c.mint(USER, stakeAmount);
    
    vm.prank(USER);
    x1c.approve(address(x1e), stakeAmount);

    // User stakes tokens
    vm.prank(USER);
    x1e.stakeTokens(stakeAmount);

    // Ensure the user has staked
    assertEq(x1e.stakedBalances(USER), stakeAmount );

    // Try to unstake before `MINIMUM_STAKING_PERIOD` has passed
    vm.prank(USER);
    vm.expectRevert(x1Engine.x1Engine__StakePeriodNotCompleted.selector);
    x1e.unstakeTokens();
    }

    function testUnstakeTokensSuccessAfterStakingPeriod() public {
    uint256 stakeAmount = 1000 ether;

    // Mint tokens to user and approve staking contract
    vm.prank(OWNER);
    x1c.mint(USER, stakeAmount);
    
    vm.prank(USER);
    x1c.approve(address(x1e), stakeAmount);

    // User stakes tokens
    vm.prank(USER);
    x1e.stakeTokens(stakeAmount);

    // Move time forward beyond minimum staking period
    vm.warp(block.timestamp + x1e.MINIMUM_STAKING_PERIOD()+1);

    // User unstakes tokens
    vm.prank(USER);
    x1e.unstakeTokens();

    // Ensure the stake balance is reset
    assertEq(x1e.stakedBalances(USER), 0, "User's stake balance should be 0");
    assertEq(x1e.stakingStartTimes(USER), 0, "User's stake time should be 0");

    // Ensure tokens + rewards are transferred
    uint256 expectedRewards = x1e.calculateRewards(USER);
    uint256 expectedBalance = stakeAmount + expectedRewards;
    uint256 actualBalance = x1c.balanceOf(USER);

    assertEq(actualBalance, expectedBalance, "User should receive stake amount plus rewards");
    }

    function testMintFailsForNonOwner() public {
        vm.prank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        x1c.mint(USER, 1000 ether);
    }

    function testMintFailsForZeroAddress() public {
        vm.prank(OWNER);
        vm.expectRevert(x1Coin.x1Coin__NotZeroAddress.selector);
        x1c.mint(address(0), 1000 ether);
    }

    function testBurnFailsIfAmountExceedsBalance() public {
        vm.prank(OWNER);
        vm.expectRevert(x1Coin.x1Coin__BurnAmountExceedsBalance.selector);
        x1c.burn(2_000_000_000 ether);
    }

    function testBurnReducesSupply() public {
        uint256 burnAmount = 1000 ether;
        uint256 initialSupply = x1c.totalSupply();
        vm.prank(OWNER);
        x1c.burn(burnAmount);
        assertEq(x1c.totalSupply(), initialSupply - burnAmount);
    }

    function testMintByOwner() public {
        vm.prank(OWNER);
        x1c.mint(USER, 1000 ether);
        assertEq(x1c.balanceOf(USER), 1000 ether);
    }

    function testMintZeroTokensFails() public {
    vm.prank(OWNER);
    vm.expectRevert(x1Coin.x1Coin__MustBeMoreThanZero.selector);
    x1c.mint(USER, 0);
    }

   function testRewardsCalculation() public {
        uint256 stakeAmount = 1000 ether;

        vm.prank(OWNER);
        x1c.mint(USER, stakeAmount);
        
        vm.prank(USER);
        x1c.approve(address(x1e), stakeAmount);

        vm.prank(USER);
        x1e.stakeTokens(stakeAmount);

        vm.warp(block.timestamp + 365 days);

        uint256 expectedRewards = (stakeAmount * x1e.REWARD_RATE()) / 100;
        uint256 actualRewards = x1e.calculateRewards(USER);
        
        assertEq(actualRewards, expectedRewards);
    }


    function testWithdrawFailsIfContractLacksFunds() public {
        uint256 stakeAmount = 1000 ether;

        vm.prank(OWNER);
        x1c.mint(USER, stakeAmount);

        vm.prank(USER);
        x1c.approve(address(x1e), stakeAmount);

        vm.prank(USER);
        x1e.stakeTokens(stakeAmount);

        vm.warp(block.timestamp + x1e.MINIMUM_STAKING_PERIOD() + 1);

        uint256 engineBalance = x1c.balanceOf(address(x1e));
        if (engineBalance > 0) {
            vm.prank(OWNER);
            x1c.transfer(address(0xdead), engineBalance);
        }

        vm.prank(USER);
        vm.expectRevert(x1Engine.x1Engine__InsufficientContractBalance.selector);
        x1e.unstakeTokens();
    }    

    function testUnstakingTwiceFails() public {
    uint256 stakeAmount = 1000 ether;

    vm.prank(OWNER);
    x1c.mint(USER, stakeAmount);
    
    vm.prank(USER);
    x1c.approve(address(x1e), stakeAmount);

    vm.prank(USER);
    x1e.stakeTokens(stakeAmount);

    vm.warp(block.timestamp + 365 days);

    vm.prank(USER);
    x1e.unstakeTokens(); // First unstake should work

    vm.expectRevert(x1Engine.x1Engine__InsufficientStakedBalance.selector);
    vm.prank(USER);
    x1e.unstakeTokens(); // Second unstake should fail
    }

}

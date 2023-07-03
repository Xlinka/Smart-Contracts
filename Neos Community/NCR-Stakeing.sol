// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NCRStaking is ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public ncrToken;

    struct StakingInfo {
        uint256 amount;
        uint256 lastStakedTime;
    }

    mapping(address => StakingInfo) public stakes;
    uint256 public stakingPeriod = 30 days;
    uint256 public rewardRate = 10;  // Reward rate in percentage

    constructor(address _ncrToken) {
        ncrToken = IERC20(_ncrToken);
    }

    function stakeTokens(uint256 _amount) public nonReentrant {
        require(stakes[msg.sender].amount == 0, "Already staked. Unstake first.");

        ncrToken.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender].amount = stakes[msg.sender].amount.add(_amount);
        stakes[msg.sender].lastStakedTime = block.timestamp;
    }

    function unstakeTokens() public nonReentrant {
        StakingInfo storage staker = stakes[msg.sender];
        require(block.timestamp >= staker.lastStakedTime.add(stakingPeriod), "Staking period not yet completed.");

        uint256 reward = calculateReward(staker.amount, staker.lastStakedTime, rewardRate);
        uint256 payout = staker.amount.add(reward);

        require(ncrToken.balanceOf(address(this)) >= payout, "Contract doesn't have enough tokens to pay out.");

        staker.amount = 0;
        staker.lastStakedTime = 0;

        ncrToken.transfer(msg.sender, payout);
    }

    function calculateReward(uint256 _amount, uint256 _stakeTime, uint256 _rewardRate) private view returns(uint256) {
        uint256 timeStaked = block.timestamp.sub(_stakeTime);
        uint256 reward = _amount.mul(_rewardRate).mul(timeStaked).div(365 days).div(100);
        return reward;
    }

    function balanceOf(address _account) public view returns(uint256) {
        return stakes[_account].amount;
    }
}

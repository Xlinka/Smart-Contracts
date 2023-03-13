// SPDX-License-Identifier: AGPL-3.0-only	
/**
This smart contract was written by Xlinka as a concept to see how easy it was to learn Solidity. The goal of this contract was
to create a basic ERC20 token, but it had several security issues and potential exploits. This updated version of the contract
fixes those issues and provides a more secure implementation of the ERC20 standard.

this was also written to prove a point that its not hard to rewrite the contract to update it to modern standards this took me 10 mins

*/
pragma solidity ^0.8.0;
pragma abicoder v2;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a, "SafeMath: subtraction underflow");
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b, "SafeMath: multiplication overflow");
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0, "SafeMath: division by zero");
        c = a / b;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed user, uint256 amount);

}

abstract contract ApproveAndCallFallback {
    function receiveApproval(address from, uint256 value, address token, bytes calldata data) external virtual;
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Owned: Only the owner can perform this action");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owned: The new owner address cannot be 0x0");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



contract NeosCredits is ERC20, Owned, SafeMath {
    string public constant symbol = "NCR";
    string public constant name = "Neos Credits";
    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 50000000000000000000000000;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => uint256) public staking;

    constructor() {
        balances[0xE581eFBa0B2a360Dc66443289a50660e9F44aC81] = _totalSupply;
        emit Transfer(address(0), 0xE581eFBa0B2a360Dc66443289a50660e9F44aC81, _totalSupply);
    }

    function totalSupply() public pure override returns (uint256) {
    return _totalSupply;
    }

    //old function
    //function balanceOf(address account) public view override returns (uint256) {
    //    return balances[account];
    //}
    
    //new balance with staking
    function balanceOf(address account) public view override returns (uint256) {
    return safeAdd(balances[account], staking[account]);
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
    require(tokens <= balances[msg.sender], "Not enough tokens");
    balances[msg.sender] = safeSub(balances[msg.sender], tokens);
    balances[to] = safeAdd(balances[to], tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        require(tokens <= balances[from], "Not enough tokens");
        require(tokens <= allowed[from][msg.sender], "Not enough allowed tokens");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function approveAndCall(address spender, uint256 tokens, bytes memory data) public returns (bool) {
    require(isContract(spender), "Contract does not implement ApproveAndCallFallback");
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    (bool success, ) = spender.call(abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", msg.sender, tokens, address(this), data));
    require(success, "Call to receiveApproval failed");
    return true;
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }


    function stake(uint256 tokens) public returns (bool) {
    require(tokens <= balances[msg.sender], "Not enough tokens");
    balances[msg.sender] = safeSub(balances[msg.sender], tokens);
    staking[msg.sender] = safeAdd(staking[msg.sender], tokens);
    emit Transfer(msg.sender, address(this), tokens);
    emit Staked(msg.sender, tokens);

    return true;
    }
    
    function unstake(uint256 tokens) public returns (bool) {
    require(tokens <= staking[msg.sender], "Not enough staked tokens");
    staking[msg.sender] = safeSub(staking[msg.sender], tokens);
    balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
    emit Transfer(address(this), msg.sender, tokens);
    return true;
    }
}


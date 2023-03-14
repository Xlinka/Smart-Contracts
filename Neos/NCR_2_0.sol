// SPDX-License-Identifier: AGPL-3.0-only	
/**
This smart contract was written by Xlinka as a concept to see how easy it was to learn Solidity. The goal of this contract was
to create a basic ERC20 token, but it had several security issues and potential exploits. This updated version of the contract
fixes those issues and provides a more secure implementation of the ERC20 standard.

this was also written to prove a point that its not hard to rewrite the contract to update it to modern standards this took me 10 mins

*/
pragma solidity ^0.8.0;
import "./NCR_2_0_Owned.sol";
import "./NCR_2_0_SafeMath.sol";
import "./NCR_2_0_ERC20.sol";
//import "./NCR_2_0_Staking.sol"; not finished implimenting

abstract contract ApproveAndCallFallback {
    function receiveApproval(address from, uint256 value, address token, bytes calldata data) external virtual;
}

contract NeosCredits is ERC20, Owned, SafeMath {
    string public constant symbol = "NCR 2.0";
    string public constant name = "Neos Credits 2.0";
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
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Safe maths
library SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: Addition overflow");

        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: Subtraction overflow");
        uint c = a - b;

        return c;
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow");

        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: Division by zero");
        uint c = a / b;

        return c;
    }
}

// ERC20 Interface
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// Contract to execute function upon approval
interface IApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

// Ownable Contract
contract Ownable {
    address public owner;
    address private newOwnerCandidate;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function proposeNewOwner(address _newOwnerCandidate) external onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwnerCandidate, "Ownable: caller is not the owner candidate");
        emit OwnershipTransferred(owner, newOwnerCandidate);
        owner = newOwnerCandidate;
        newOwnerCandidate = address(0);
    }
}

// Token Contract
contract NeosCredits is IERC20, Ownable {
    using SafeMath for uint;

    string public constant symbol = "NCR";
    string public constant name = "Neos Credits";
    uint8 public constant decimals = 18;
    uint private _totalSupply = 50000000 * 10**decimals;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    constructor() {
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    function transfer(address to, uint tokens) public override returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].safeSub(tokens);
        _balances[to] = _balances[to].safeAdd(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool) {
        require(tokens == 0 || _allowances[msg.sender][spender] == 0);
        _allowances[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool) {
        _balances[from] = _balances[from].safeSub(tokens);
        _allowances[from][msg.sender] = _allowances[from][msg.sender].safeSub(tokens);
        _balances[to] = _balances[to].safeAdd(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool) {
        require(approve(spender, tokens));
        IApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool) {
        return IERC20(tokenAddress).transfer(owner, tokens);
    }

    receive() external payable {
        revert("Does not accept ETH");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only	
pragma solidity ^0.8.0;
import "./NCR_2_0.sol";

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

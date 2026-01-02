// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract EscrowStep1 {
    
    // State variables (1)
    address payable public owner;
    address payable public receiver;
    uint256 public amount;
    bool public funded;

    // Event (2)
    event Deposited(address indexed from, uint256 value);
    event Released(address indexed to, uint256 value);

    // Modifier (3)
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    // constructor (4)
    constructor(address payable _receiver) payable {
        require(_receiver != address(0), "Invalid receiver");

        owner = payable(msg.sender);
        receiver = _receiver;
    }

    // Deposit Function (5)
    function deposit() external payable onlyOwner {
        require(!funded, "Already funded");
        require(msg.value > 0, "Send ETH");

        amount = msg.value;
        funded = true;

        emit Deposited(msg.sender, msg.value);
    }

    // Step 2: Release Funtion
    function release() external onlyOwner {
        uint256 payout = address(this).balance;
        
        require(payout > 0, "No funds to release");
        
    
        amount = 0;
        funded = false;

        (bool sent, ) = receiver.call{value: payout}(""); 
        require(sent, "Transfer to receive failed");

        emit Released(receiver, payout);
    }
}
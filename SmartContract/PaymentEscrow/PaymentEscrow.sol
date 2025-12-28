// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PaymentEscrow {
    address public owner;
    address payable public receiver;

    bool public released;
    bool public refunded;

    constructor(address payable _receiver) {
        owner = msg.sender; // Account 1 (client)
        receiver = _receiver; // Account 2 (freelancer)
    }

    // 1️⃣ Deposit ETH into contract
    function deposit() public payable {
        require(msg.sender == owner, "Only owner can deposit");
        require(msg.value > 0, "Send some ETH");
    }

    // 2️⃣ Release payment to receiver
    function releasePayment() public {
        require(msg.sender == owner, "Only owner");
        require(!released, "Already released");
        require(!refunded, "Already refunded");

        released = true;
        (bool success, ) = receiver.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // 3️⃣ Refund payment to owner
    function refund() public {
        require(msg.sender == owner, "Only owner");
        require(!released, "Already released");
        require(!refunded, "Already refunded");

        refunded = true;
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // Helper: check contract balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

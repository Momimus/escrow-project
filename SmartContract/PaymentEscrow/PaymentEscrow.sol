// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simple Escrow (beginner-friendly)
/// @notice Owner deposits ETH, can release to receiver or refund to owner. Single active deposit.
contract Escrow {
    address payable public owner;
    address payable public receiver;
    uint256 public amount;    // amount locked (wei)
    bool public funded;
    bool private locked;      // simple reentrancy guard

    event Deposited(address indexed from, uint256 value);
    event Released(address indexed to, uint256 value);
    event Refunded(address indexed to, uint256 value);
    event ReceiverChanged(address indexed oldReceiver, address indexed newReceiver);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrant");
        locked = true;
        _;
        locked = false;
    }

    constructor(address payable _receiver) {
        require(_receiver != address(0), "Receiver is zero address");
        owner = payable(msg.sender);
        receiver = _receiver;
    }

    /// Deposit ETH into the escrow. Only owner, only when not already funded.
    function deposit() external payable onlyOwner {
        require(!funded, "Escrow already funded");
        require(msg.value > 0, "Must send > 0 ETH");

        // store deposit amount explicitly from msg.value
        amount = msg.value;
        funded = true;

        emit Deposited(msg.sender, msg.value);
    }

    /// Release funds to receiver. Only owner.
    function release() external onlyOwner nonReentrant {
        require(funded, "No funds to release");

        uint256 payout = amount;

        // Effects
        funded = false;
        amount = 0;

        // Interaction: use call to forward gas and bubble up failure
        (bool ok, ) = receiver.call{value: payout}("");
        require(ok, "Transfer to receiver failed");

        emit Released(receiver, payout);
    }

    /// Refund funds back to owner. Only owner.
    function refund() external onlyOwner nonReentrant {
        require(funded, "No funds to refund");

        uint256 payout = amount;

        funded = false;
        amount = 0;

        (bool ok, ) = owner.call{value: payout}("");
        require(ok, "Refund failed");

        emit Refunded(owner, payout);
    }

    function changeReceiver(address payable _new) external onlyOwner {
        require(_new != address(0), "Invalid new receiver");
        address old = receiver;
        receiver = _new;
        emit ReceiverChanged(old, _new);
    }

    // Helpers
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Prevent accidental plain transfers; force use of deposit()
    receive() external payable {
        revert("Use deposit()");
    }

    fallback() external payable {
        revert("Use deposit()");
    }
}
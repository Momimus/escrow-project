// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simple Escrow (beginner-friendly)
/// @notice Owner deposits ETH, can release to receiver or refund to owner. Optionally accept initial funding at deploy.
contract Escrow {
    address payable public owner;
    address payable public receiver;
    uint256 public amount;    // locked amount in wei
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

    /// @dev Payable constructor: allows optional initial funding at deployment.
    constructor(address payable _receiver) payable {
        require(_receiver != address(0), "Receiver is zero address");
        owner = payable(msg.sender);
        receiver = _receiver;
        if (msg.value > 0) {
            amount = msg.value;
            funded = true;
            emit Deposited(msg.sender, msg.value);
        }
    }

    /// @notice Deposit ETH into the escrow. Only owner and only when not already funded.
    function deposit() external payable onlyOwner {
        require(!funded, "Escrow already funded");
        require(msg.value > 0, "Must send > 0 ETH");
        amount = msg.value;
        funded = true;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Release funds to the receiver. Only owner.
    function release() external onlyOwner nonReentrant {
        require(funded, "No funds to release");
        uint256 payout = amount;

        // Effects
        funded = false;
        amount = 0;

        // Interaction: use call and check result
        (bool sent, ) = receiver.call{value: payout}("");
        require(sent, "Transfer to receiver failed");

        emit Released(receiver, payout);
    }

    /// @notice Refund funds back to owner. Only owner.
    function refund() external onlyOwner nonReentrant {
        require(funded, "No funds to refund");
        uint256 payout = amount;

        funded = false;
        amount = 0;

        (bool sent, ) = owner.call{value: payout}("");
        require(sent, "Refund to owner failed");

        emit Refunded(owner, payout);
    }

    /// @notice Change receiver (only owner).
    function changeReceiver(address payable _newReceiver) external onlyOwner {
        require(_newReceiver != address(0), "Invalid receiver");
        address old = receiver;
        receiver = _newReceiver;
        emit ReceiverChanged(old, _newReceiver);
    }

    /// @notice Helper: check contract balance
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// Prevent accidental plain transfers after deployment; force use of deposit().
    receive() external payable {
        revert("Use deposit()");
    }

    fallback() external payable {
        revert("Use deposit()");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TransferWithExactRepetitionTrap.sol";

contract TransferWithExactRepetitionTrapTest is Test {
    TransferWithExactRepetitionTrap trap;

    struct TransferEvent {
        address from;
        address to;
        uint256 amount;
    }

    function setUp() public {
        trap = new TransferWithExactRepetitionTrap();
    }

    function testShouldNotRespondIfNoRepetition() public view {
        TransferEvent[] memory logs = new TransferEvent[](2);
        logs[0] = TransferEvent({from: address(1), to: address(100), amount: 1 ether});
        logs[1] = TransferEvent({from: address(2), to: address(101), amount: 1 ether});

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(true);
        data[1] = abi.encode(logs);

        (bool triggered, bytes memory message) = trap.shouldRespond(data);
        assertFalse(triggered);
        assertEq(message, "");
    }

    function testShouldRespondOnRepeatedTransfer() public view {
        TransferEvent[] memory logs = new TransferEvent[](3);
        logs[0] = TransferEvent({from: address(1), to: address(200), amount: 2 ether});
        logs[1] = TransferEvent({from: address(2), to: address(200), amount: 2 ether}); // repetition
        logs[2] = TransferEvent({from: address(3), to: address(201), amount: 1 ether});

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(true);
        data[1] = abi.encode(logs);

        (bool triggered, bytes memory message) = trap.shouldRespond(data);
        assertTrue(triggered);
        assertEq(string(message), "Repeated transfers detected");
    }
}

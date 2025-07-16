// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/TransferWithExactRepetitionTrap.sol";

contract TransferWithExactRepetitionTrapTest is Test {
    TransferWithExactRepetitionTrap trap;
    
    function setUp() public {
        trap = new TransferWithExactRepetitionTrap();
    }
    
    function testShouldNotRespondIfNoRepetition() public view {
        TransferWithExactRepetitionTrap.TransferEvent[] memory logs = new TransferWithExactRepetitionTrap.TransferEvent[](2);
        logs[0] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(1), 
            to: address(100), 
            amount: 1 ether,
            blockNumber: 1000,
            txHash: keccak256("tx1"),
            timestamp: block.timestamp
        });
        logs[1] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(2), 
            to: address(101), 
            amount: 1 ether,
            blockNumber: 1001,
            txHash: keccak256("tx2"),
            timestamp: block.timestamp + 1
        });
        
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(true);
        data[1] = abi.encode(logs);
        
        (bool triggered, bytes memory message) = trap.shouldRespond(data);
        assertFalse(triggered);
        assertEq(message, "");
    }
    
    function testShouldRespondOnRepeatedTransfer() public view {
        TransferWithExactRepetitionTrap.TransferEvent[] memory logs = new TransferWithExactRepetitionTrap.TransferEvent[](3);
        logs[0] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(1), 
            to: address(200), 
            amount: 2 ether,
            blockNumber: 1000,
            txHash: keccak256("tx1"),
            timestamp: block.timestamp
        });
        logs[1] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(2), 
            to: address(200), 
            amount: 2 ether,
            blockNumber: 1001,
            txHash: keccak256("tx2"),
            timestamp: block.timestamp + 1
        });
        logs[2] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(3), 
            to: address(201), 
            amount: 1 ether,
            blockNumber: 1002,
            txHash: keccak256("tx3"),
            timestamp: block.timestamp + 2
        });
        
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(true);
        data[1] = abi.encode(logs);
        
        (bool triggered, bytes memory message) = trap.shouldRespond(data);
        assertTrue(triggered);
        
        string memory decodedMessage = abi.decode(message, (string));
        assertEq(decodedMessage, "Repeated transfers from different senders detected");
    }
    
    function testShouldRespondOnSameBlockRepetition() public view {
        TransferWithExactRepetitionTrap.TransferEvent[] memory logs = new TransferWithExactRepetitionTrap.TransferEvent[](2);
        logs[0] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(1), 
            to: address(200), 
            amount: 2 ether,
            blockNumber: 1000,
            txHash: keccak256("tx1"),
            timestamp: block.timestamp
        });
        logs[1] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(1), 
            to: address(200), 
            amount: 2 ether,
            blockNumber: 1000,
            txHash: keccak256("tx2"),
            timestamp: block.timestamp
        });
        
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(true);
        data[1] = abi.encode(logs);
        
        (bool triggered, bytes memory message) = trap.shouldRespond(data);
        assertTrue(triggered);
        
        string memory decodedMessage = abi.decode(message, (string));
        assertEq(decodedMessage, "Multiple identical transfers in same block detected");
    }
    
    function testShouldRespondOnRegularRepetition() public view {
        TransferWithExactRepetitionTrap.TransferEvent[] memory logs = new TransferWithExactRepetitionTrap.TransferEvent[](2);
        logs[0] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(1),
            to: address(200), 
            amount: 2 ether,
            blockNumber: 1000,
            txHash: keccak256("tx1"),
            timestamp: block.timestamp
        });
        logs[1] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(1),
            to: address(200),
            amount: 2 ether,
            blockNumber: 1001,
            txHash: keccak256("tx2"),
            timestamp: block.timestamp + 1
        });
        
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(true);
        data[1] = abi.encode(logs);
        
        (bool triggered, bytes memory message) = trap.shouldRespond(data);
        assertTrue(triggered);
        
        string memory decodedMessage = abi.decode(message, (string));
        assertEq(decodedMessage, "Repeated transfers detected");
    }
    
    function testShouldNotRespondOnEmptyData() public view {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(true);
        
        (bool triggered, bytes memory message) = trap.shouldRespond(data);
        assertFalse(triggered);
        assertEq(message, "");
    }
    
    function testShouldNotRespondOnInvalidDataLength() public view {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(true);
    
        data[1] = abi.encode("");
    
        (bool triggered, bytes memory message) = trap.shouldRespond(data);

        assertFalse(triggered);
        assertEq(message, "");
    }
    
    function testShouldNotRespondOnTooManyLogs() public view {
        TransferWithExactRepetitionTrap.TransferEvent[] memory logs = new TransferWithExactRepetitionTrap.TransferEvent[](1001);
        for (uint256 i = 0; i < 1001; i++) {
            logs[i] = TransferWithExactRepetitionTrap.TransferEvent({
                from: address(uint160(i + 1)), 
                to: address(uint160(i + 100)), 
                amount: 1 ether,
                blockNumber: 1000 + i,
                txHash: keccak256(abi.encode(i)),
                timestamp: block.timestamp + i
            });
        }
        
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(true);
        data[1] = abi.encode(logs);
        
        (bool triggered, bytes memory message) = trap.shouldRespond(data);
        assertFalse(triggered);
        assertEq(message, "");
    }
    
    function testInjectLogs() public {
        TransferWithExactRepetitionTrap.TransferEvent[] memory logs = new TransferWithExactRepetitionTrap.TransferEvent[](2);
        logs[0] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(1), 
            to: address(100), 
            amount: 1 ether,
            blockNumber: 1000,
            txHash: keccak256("tx1"),
            timestamp: block.timestamp
        });
        logs[1] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(2), 
            to: address(101), 
            amount: 2 ether,
            blockNumber: 1001,
            txHash: keccak256("tx2"),
            timestamp: block.timestamp + 1
        });
        
        trap.injectLogs(logs);
        
        assertEq(trap.getInjectedLogsCount(), 2);
        
        TransferWithExactRepetitionTrap.TransferEvent memory retrievedLog = trap.getInjectedLog(0);
        assertEq(retrievedLog.from, address(1));
        assertEq(retrievedLog.to, address(100));
        assertEq(retrievedLog.amount, 1 ether);
    }
    
    function testCollectInjectedLogs() public {
        TransferWithExactRepetitionTrap.TransferEvent[] memory logs = new TransferWithExactRepetitionTrap.TransferEvent[](1);
        logs[0] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(1), 
            to: address(100), 
            amount: 1 ether,
            blockNumber: 1000,
            txHash: keccak256("tx1"),
            timestamp: block.timestamp
        });
        
        trap.injectLogs(logs);
        
        bytes memory collectedData = trap.collect();
        
        TransferWithExactRepetitionTrap.TransferEvent[] memory collectedLogs = abi.decode(collectedData, (TransferWithExactRepetitionTrap.TransferEvent[]));
        
        assertEq(collectedLogs.length, 1);
        assertEq(collectedLogs[0].from, address(1));
        assertEq(collectedLogs[0].to, address(100));
        assertEq(collectedLogs[0].amount, 1 ether);
    }
    
    function testPrepareDataForShouldRespond() public {
        TransferWithExactRepetitionTrap.TransferEvent[] memory logs = new TransferWithExactRepetitionTrap.TransferEvent[](2);
        logs[0] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(1), 
            to: address(200), 
            amount: 2 ether,
            blockNumber: 1000,
            txHash: keccak256("tx1"),
            timestamp: block.timestamp
        });
        logs[1] = TransferWithExactRepetitionTrap.TransferEvent({
            from: address(2), 
            to: address(200), 
            amount: 2 ether,
            blockNumber: 1001,
            txHash: keccak256("tx2"),
            timestamp: block.timestamp + 1
        });
        
        trap.injectLogs(logs);
        
        bytes[] memory data = trap.prepareDataForShouldRespond();
        
        (bool triggered, bytes memory message) = trap.shouldRespond(data);
        assertTrue(triggered);
        
        string memory decodedMessage = abi.decode(message, (string));
        assertEq(decodedMessage, "Repeated transfers from different senders detected");
    }
}
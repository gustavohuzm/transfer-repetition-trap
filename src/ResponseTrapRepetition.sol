// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrapConfig {
    function owner() external view returns (address);
}

interface IDrosera {
    function getRewardAddress(address _trap) external view returns (address);
}

interface ITransferWithExactRepetitionTrap {
    struct TransferEvent {
        address from;
        address to;
        uint256 amount;
    }
}

contract ResponseToTransferRepetition {
    address public immutable droseraSystem;

    struct RepeatedTransferLog {
        address recipient;
        uint128 amount;
        uint64 timestamp;
        address trapOwner;
    }

    RepeatedTransferLog[] public repeatedTransferLogs;

    mapping(address => mapping(bytes32 => bool)) public hasLoggedRepeatedTransfer;

    event RepeatedTransferLogged(
        address indexed trapAddress,
        address indexed trapOwner,
        address indexed recipient,
        uint128 amount,
        uint64 timestamp
    );

    constructor(address _droseraSystem) {
        require(_droseraSystem != address(0), "Drosera system address cannot be zero");
        droseraSystem = _droseraSystem;
    }

    function respondToRepetition(bytes[] calldata _data) external {
        IDrosera(droseraSystem).getRewardAddress(msg.sender);

        address trapOwner = ITrapConfig(msg.sender).owner();

        ITransferWithExactRepetitionTrap.TransferEvent[] memory logs =
            abi.decode(_data[1], (ITransferWithExactRepetitionTrap.TransferEvent[]));

        uint256 logCount = logs.length;
        if (logCount == 0 || logCount > 100) revert("Invalid log size");

        bytes32[] memory keysSeen = new bytes32[](logCount);
        uint256[] memory counts = new uint256[](logCount);
        uint256 uniqueKeyCount = 0;

        bytes32 repeatedKey;
        bool foundRepetition = false;

        for (uint256 i = 0; i < logCount; i++) {
            bytes32 currentKey = keccak256(abi.encode(logs[i].to, logs[i].amount));
            bool found = false;

            for (uint256 j = 0; j < uniqueKeyCount; j++) {
                if (keysSeen[j] == currentKey) {
                    counts[j]++;
                    found = true;
                    if (counts[j] >= 2) {
                        repeatedKey = currentKey;
                        foundRepetition = true;
                        break;
                    }
                }
            }

            if (!found) {
                keysSeen[uniqueKeyCount] = currentKey;
                counts[uniqueKeyCount] = 1;
                uniqueKeyCount++;
            }

            if (foundRepetition) break;
        }
        require(foundRepetition, "No repetition detected");

        address detectedRecipient = address(0);
        uint128 detectedAmount = 0;

        for (uint256 i = 0; i < logCount; i++) {
            if (keccak256(abi.encode(logs[i].to, logs[i].amount)) == repeatedKey) {
                detectedRecipient = logs[i].to;
                detectedAmount = uint128(logs[i].amount);
                break;
            }
        }

        if (!hasLoggedRepeatedTransfer[trapOwner][repeatedKey]) {
            repeatedTransferLogs.push(
                RepeatedTransferLog({
                    recipient: detectedRecipient,
                    amount: detectedAmount,
                    timestamp: uint64(block.timestamp),
                    trapOwner: trapOwner
                })
            );

            hasLoggedRepeatedTransfer[trapOwner][repeatedKey] = true;

            emit RepeatedTransferLogged(
                msg.sender,
                trapOwner,
                detectedRecipient,
                detectedAmount,
                uint64(block.timestamp)
            );
        }
    }

    function getRepeatedTransferLog(uint256 _index) external view returns (
        address recipient,
        uint128 amount,
        uint64 timestamp,
        address trapOwner
    ) {
        require(_index < repeatedTransferLogs.length, "Index out of bounds");
        RepeatedTransferLog storage log = repeatedTransferLogs[_index];
        return (log.recipient, log.amount, log.timestamp, log.trapOwner);
    }

    function getRepeatedTransferLogsCount() external view returns (uint256) {
        return repeatedTransferLogs.length;
    }
}
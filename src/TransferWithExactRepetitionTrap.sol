// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

contract TransferWithExactRepetitionTrap is ITrap {
    struct TransferEvent {
        address from;
        address to;
        uint256 amount;
        uint256 blockNumber;
        bytes32 txHash;
        uint256 timestamp;
    }

    TransferEvent[] private injectedLogs;
    uint256 private lastCollectionBlock;
    address public nodeOperator;
    
    event LogsInjected(uint256 count, uint256 blockNumber);
    event LogsCollected(uint256 count);
    
    modifier onlyNodeOperator() {
        require(msg.sender == nodeOperator, "Only node operator can inject logs");
        _;
    }

    constructor() {
        nodeOperator = msg.sender;
        lastCollectionBlock = block.number;
    }

    function initialize(address _nodeOperator) external {
        require(nodeOperator == msg.sender, "Only current operator can change");
        require(_nodeOperator != address(0), "Invalid operator address");
        nodeOperator = _nodeOperator;
    }

    function injectLogs(TransferEvent[] calldata _logs) external onlyNodeOperator {
        require(_logs.length > 0, "No logs to inject");
        require(_logs.length <= 1000, "Too many logs in single injection");
        
        delete injectedLogs;
        
        for (uint256 i = 0; i < _logs.length; i++) {
            injectedLogs.push(_logs[i]);
        }
        
        emit LogsInjected(_logs.length, block.number);
    }

    function injectLogsBatch(
        TransferEvent[] calldata _logs,
        uint256 _startIndex,
        bool _isLastBatch
    ) external onlyNodeOperator {
        require(_logs.length > 0, "No logs to inject");
        require(_logs.length <= 100, "Batch size too large");
        
        if (_startIndex == 0) {
            delete injectedLogs;
        }
        
        for (uint256 i = 0; i < _logs.length; i++) {
            injectedLogs.push(_logs[i]);
        }
        
        if (_isLastBatch) {
            emit LogsInjected(injectedLogs.length, block.number);
        }
    }

    function collect() external view returns (bytes memory) {
        if (injectedLogs.length == 0) {
            return abi.encode(new TransferEvent[](0));
        }
        
        TransferEvent[] memory logsToReturn = new TransferEvent[](injectedLogs.length);
        for (uint256 i = 0; i < injectedLogs.length; i++) {
            logsToReturn[i] = injectedLogs[i];
        }
        
        return abi.encode(logsToReturn);
    }

    function collectByBlockRange(uint256 _fromBlock, uint256 _toBlock) external view returns (bytes memory) {
        require(_fromBlock <= _toBlock, "Invalid block range");
        
        uint256 count = 0;
        for (uint256 i = 0; i < injectedLogs.length; i++) {
            if (injectedLogs[i].blockNumber >= _fromBlock && injectedLogs[i].blockNumber <= _toBlock) {
                count++;
            }
        }
        
        if (count == 0) {
            return abi.encode(new TransferEvent[](0));
        }
        
        TransferEvent[] memory filteredLogs = new TransferEvent[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < injectedLogs.length; i++) {
            if (injectedLogs[i].blockNumber >= _fromBlock && injectedLogs[i].blockNumber <= _toBlock) {
                filteredLogs[index] = injectedLogs[i];
                index++;
            }
        }
        
        return abi.encode(filteredLogs);
    }

    function shouldRespond(bytes[] calldata _data) external pure returns (bool, bytes memory) {
        if (_data.length < 2 || _data[1].length < 96) {
            return (false, bytes(""));
        }
        
        TransferEvent[] memory logs = abi.decode(_data[1], (TransferEvent[]));
        
        uint256 logCount = logs.length;
        if (logCount == 0 || logCount > 1000) {
            return (false, bytes(""));
        }

        for (uint256 i = 0; i < logCount; i++) {
            for (uint256 j = i + 1; j < logCount; j++) {
                if (logs[i].to == logs[j].to && logs[i].amount == logs[j].amount) {
                    if (logs[i].from != logs[j].from) {
                        return (true, abi.encode("Repeated transfers from different senders detected"));
                    } else if (logs[i].blockNumber == logs[j].blockNumber) {
                        return (true, abi.encode("Multiple identical transfers in same block detected"));
                    } else {
                        return (true, abi.encode("Repeated transfers detected"));
                    }
                }
            }
        }
        
        return (false, bytes(""));
    }

    function prepareDataForShouldRespond() external view returns (bytes[] memory) {
        bytes[] memory data = new bytes[](2);
        data[0] = bytes("");
        data[1] = this.collect();
        return data;
    }

    function decodeTransferEvents(bytes calldata _data) external pure returns (TransferEvent[] memory) {
        return abi.decode(_data, (TransferEvent[]));
    }

    function getInjectedLogsCount() external view returns (uint256) {
        return injectedLogs.length;
    }

    function getInjectedLog(uint256 _index) external view returns (TransferEvent memory) {
        require(_index < injectedLogs.length, "Index out of bounds");
        return injectedLogs[_index];
    }

    function updateNodeOperator(address _newOperator) external onlyNodeOperator {
        require(_newOperator != address(0), "Invalid operator address");
        nodeOperator = _newOperator;
    }

    function clearLogs() external onlyNodeOperator {
        delete injectedLogs;
        emit LogsCollected(0);
    }

    function getLastCollectionBlock() external view returns (uint256) {
        return lastCollectionBlock;
    }
}
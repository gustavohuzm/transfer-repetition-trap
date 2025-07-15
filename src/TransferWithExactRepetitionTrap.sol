// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

contract TransferWithExactRepetitionTrap is ITrap {
    struct TransferEvent {
        address from;
        address to;
        uint256 amount;
    }

    constructor() {}

    function collect() external view returns (bytes memory) {
        return abi.encode(true);
    }

    function shouldRespond(bytes[] calldata _data) external pure returns (bool, bytes memory) {
        if (_data.length < 2 || _data[1].length < 96) {
            return (false, bytes(""));
        }

        TransferEvent[] memory logs = abi.decode(_data[1], (TransferEvent[]));

        uint256 logCount = logs.length;
        if (logCount == 0 || logCount > 100) {
            return (false, bytes(""));
        }

        for (uint256 i = 0; i < logCount; i++) {
            for (uint256 j = i + 1; j < logCount; j++) {
                if (logs[i].to == logs[j].to && logs[i].amount == logs[j].amount) {
                    return (true, bytes("Repeated transfers detected"));
                }
            }
        }

        return (false, bytes(""));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../interfaces/IAllocationStrategy.sol";
import "../../interfaces/IDistributionStrategy.sol";
import "../../core/Allo.sol";
import "../../core/Registry.sol";
import "../../core/libraries/Transfer.sol";


contract SplitterDistributionStrategy is IDistributionStrategy {

    error CALLER_NOT_ALLO();

    uint256 public poolId;
    Allo public allo;

    struct Payout {
        address to;
        uint256 amount;
    }

    modifier isAllo() {
        if(msg.sender == address(allo)) {
            revert CALLER_NOT_ALLO();
        }
        _;
    }

    constructor(uint256 _poolId, address _allo) {
        poolId = _poolId;
        allo = Allo(_allo);
    }

    function getOwnerIdentity() external view returns (string memory) {
        return allo.pools[poolId].identityId;
    }

    function activateDistribution(bytes memory _inputData) external isAllo {
        IAllocationStrategy allocationStrategy = Allo(allo).projects[poolId].allocationStrategy;
        bytes dataFromAllocationStrategy = allocationStrategy.generatePayouts();
        // set Payouts
    }

    function distribute(bytes memory _data, address sender) external isAllo {
        Payout[] memory payouts = abi.decode(_data, (Payout[]));
        address token = allo.pools[poolId].token;
        transferTokens(_data, token);
        Transfer._transferAmount(_token, payouts);
    }

}
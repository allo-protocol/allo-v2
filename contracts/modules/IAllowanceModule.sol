// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IAllowanceModule {
    // We use a double linked list for the delegates. The id is the first 6 bytes.
    // To double check the address in case of collision, the address is part of the struct.
    struct Delegate {
        address delegate;
        uint48 prev;
        uint48 next;
    }

    // The allowance info is optimized to fit into one word of storage.
    struct Allowance {
        uint96 amount;
        uint96 spent;
        uint16 resetTimeMin; // Maximum reset time span is 65k minutes
        uint32 lastResetMin;
        uint16 nonce;
    }

    function setAllowance(
        address delegate,
        address token,
        uint96 allowanceAmount,
        uint16 resetTimeMin,
        uint32 resetBaseMin
    ) external;
    function addDelegate(address delegate) external;

    function executeAllowanceTransfer(
        address safe,
        address token,
        address payable to,
        uint96 amount,
        address paymentToken,
        uint96 payment,
        address delegate,
        bytes memory signature
    ) external;

    function getAllowance(address safe, address delegate, address token)
        external
        view
        returns (Allowance memory allowance);
    function getTokens(address safe, address delegate) external view returns (address[] memory);
    function getTokenAllowance(address safe, address delegate, address token)
        external
        view
        returns (uint256[5] memory);
    function generateTransferHash(
        address safe,
        address token,
        address to,
        uint96 amount,
        address paymentToken,
        uint96 payment,
        uint16 nonce
    ) external view returns (bytes32);
}

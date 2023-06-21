// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IRegistry} from "./interfaces/IRegistry.sol";
import {Metadata} from "../core/libraries/Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Registry is Initializable, IRegistry {
    // A linked list of owners of a identity
    // The use of a linked list allows us to easily add and remove owners,
    // access them directly in O(1), and loop through them.
    //
    // {
    //     count: 3,
    //     list: {
    //         OWNERS_LIST_SENTINEL => owner1Address,
    //         owner1Address => owner2Address,
    //         owner2Address => owner3Address,
    //         owner3Address => OWNERS_LIST_SENTINEL
    //     }
    // }
    struct OwnerList {
        uint256 count;
        mapping(uint => address) list;
    }

    // State variables

    // Used as sentinel value in the owners linked list.
    address constant _OWNERS_LIST_SENTINEL = address(0x1);

    // The mapping of identities, from identityId to IdentityDetails
    mapping(uint => IdentityDetails) public identities;

    // The mapping identities owners, from identityId to OwnerList
    mapping(address => OwnerList) public identityOwners;

    // Events

    event IdentityCreated(uint indexed identityId, address indexed owner);
    event MetadataUpdated(uint indexed identityId, IdentityDetails metaPtr);
    event OwnerAdded(uint indexed identityId, address indexed owner);
    event OwnerRemoved(uint indexed identityId, address indexed owner);

    // Modifiers

    modifier onlyIdentityOwner(uint identityId) {
        require(
            identityOwners[identityId].list[msg.sender] != address(0),
            "PR000"
        );
        _;
    }

    /**
     * @notice Initializes the contract after an upgrade
     * @dev In future deploys of the implementation, an higher version should be passed to reinitializer
     */
    function initialize() public reinitializer(1) {}

    // External functions

    // This function will retrieve the identity details associated with the provided identityId.
    function getIdentity(uint _identityId) external view override returns (IdentityDetails memory) {
        return identities[_identityId];
    }

    // This function creates a new identity and returns its ID (for this example, we're just using a counter as the ID).
    function createIdentity(
        IdentityDetails memory _identityDetails,
        address[] memory _owners
    ) external override returns (uint256) {
        // Implement the function here, including updating the mapping and handling the owners array.
    }

    // This function checks if a specific address is an owner of a specific identity.
    function isOwnerOfIdentity(
        uint _identityId,
        address _owner
    ) external view override returns (bool) {
        // Implement the function here, possibly using the Solmate Roles library as mentioned in the comments.
    }

    function updateIdentityName(
        uint _identityId,
        string memory _name
    ) external override {
        // check if the caller has the right to update the identity
        require(
            this.isOwnerOfIdentity(_identityId, msg.sender),
            "Caller is not owner of this identity"
        );

        // update the name of the identity
        identities[_identityId].name = _name;
        // Also may want to update the attestation address. This will depend on how we generate our attestation addresses.
        // identities[_identityId].attestationAddress = ... ;
    }

    /**
     * @notice Updates Metadata for singe identity
     * @param identityId ID of previously created identity
     * @param metadata Updated pointer to external metadata
     */
    function updateIdentityMetadata(
        uint identityId,
        string calldata metadata
    ) external override onlyIdentityOwner(identityId) {
        // this is a permissionless update
        // ZACH: this should just be updating metadata string, not that no permissions/permissionless split
        // identities[identityId].permissionlessMetadata = metadata
        //     .permissionlessMetadata;
        // emit MetadataUpdated(identityId, metadata);
    }

    /**
     * @notice Associate a new owner with a identity
     * @param identityId ID of previously created identity
     * @param newOwner address of new identity owner
     */
    function addIdentityOwner(
        uint identityId,
        address newOwner
    ) external onlyIdentityOwner(identityId) {
        require(
            newOwner != address(0) &&
                newOwner != _OWNERS_LIST_SENTINEL &&
                newOwner != address(this),
            "PR001"
        );

        OwnerList storage owners = identityOwners[identityId];

        require(owners.list[newOwner] == address(0), "PR002");

        owners.list[newOwner] = owners.list[_OWNERS_LIST_SENTINEL];
        owners.list[_OWNERS_LIST_SENTINEL] = newOwner;
        owners.count++;

        emit OwnerAdded(identityId, newOwner);
    }

    /**
     * @notice Disassociate an existing owner from a identity
     * @param identityId ID of previously created identity
     * @param prevOwner Address of previous owner in OwnerList
     * @param owner Address of new Owner
     */
    function removeIdentityOwner(
        uint identityId,
        address prevOwner,
        address owner
    ) external onlyIdentityOwner(identityId) {
        require(owner != address(0) && owner != _OWNERS_LIST_SENTINEL, "PR001");

        OwnerList storage owners = identityOwners[identityId];

        require(owners.list[prevOwner] == owner, "PR003");
        require(owners.count > 1, "PR004");

        owners.list[prevOwner] = owners.list[owner];
        delete owners.list[owner];
        owners.count--;

        emit OwnerRemoved(identityId, owner);
    }

    // Public functions

    /**
     * @notice Retrieve count of existing identity owners
     * @param identityId ID of identity
     * @return Count of owners for given identity
     */
    function identityOwnersCount(
        uint identityId
    ) external view returns (uint256) {
        return identityOwners[identityId].count;
    }

    /**
     * @notice Retrieve list of identity owners
     * @param identityId ID of identity
     * @return List of current owners of given identity
     */
    function getProjectOwners(
        uint identityId
    ) external view returns (address[] memory) {
        OwnerList storage owners = identityOwners[identityId];

        address[] memory list = new address[](owners.count);

        uint256 index = 0;
        address current = owners.list[_OWNERS_LIST_SENTINEL];

        if (current == address(0x0)) {
            return list;
        }

        while (current != _OWNERS_LIST_SENTINEL) {
            list[index] = current;
            current = owners.list[current];
            index++;
        }

        return list;
    }

    // Internal functions

    /**
     * @notice Create initial OwnerList for passed identity
     * @param identityId ID of identity
     */
    function _initIdentityOwners(uint identityId) internal {
        OwnerList storage owners = identityOwners[identityId];

        owners.list[_OWNERS_LIST_SENTINEL] = msg.sender;
        owners.list[msg.sender] = _OWNERS_LIST_SENTINEL;
        owners.count = 1;
    }

    // Private functions
    // ...
}

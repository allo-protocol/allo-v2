// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {MetaPtr} from "./utils/MetaPtr.sol";
// import {IRegistry} from "./interfaces/IRegistry.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Registry is Initializable {
// Types

    // The identity struct contains the minimal data we need for a identity
    struct Identity {
        uint256 id;
        MetaPtr metadata;
    }

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
        mapping(address => address) list;
    }

    // State variables

    // Used as sentinel value in the owners linked list.
    address constant OWNERS_LIST_SENTINEL = address(0x1);

    // The number of identities created, used to give an incremental id to each one
    uint256 public identitiesCount;

    // The mapping of identities, from identityId to Project
    mapping(uint256 => Identity) public identities;

    // The mapping identities owners, from identityId to OwnerList
    mapping(uint256 => OwnerList) public identityOwners;

    // Events

    event ProjectCreated(uint256 indexed identityId, address indexed owner);
    event MetadataUpdated(uint256 indexed identityId, MetaPtr metaPtr);
    event OwnerAdded(uint256 indexed identityId, address indexed owner);
    event OwnerRemoved(uint256 indexed identityId, address indexed owner);

    // Modifiers

    modifier onlyProjectOwner(uint256 identityId) {
        require(identityOwners[identityId].list[msg.sender] != address(0), "PR000");
        _;
    }

    /**
     * @notice Initializes the contract after an upgrade
     * @dev In future deploys of the implementation, an higher version should be passed to reinitializer
     */
    function initialize() public reinitializer(1) {
    }

    // External functions

    /**
     * @notice Creates a new project with a metadata pointer
     * @param metadata the metadata pointer
     */
    function createProject(MetaPtr calldata metadata) external {
        uint256 identityId = identitiesCount++;

        Identity storage identity = identities[identityId];
        identity.id = identityId;
        identity.metadata = metadata;

        initProjectOwners(identityId);

        emit ProjectCreated(identityId, msg.sender);
        emit MetadataUpdated(identityId, metadata);
    }

    /**
     * @notice Updates Metadata for singe project
     * @param identityId ID of previously created project
     * @param metadata Updated pointer to external metadata
     */
    function updateProjectMetadata(uint256 identityId, MetaPtr calldata metadata) external onlyProjectOwner(identityId) {
        identities[identityId].metadata = metadata;
        emit MetadataUpdated(identityId, metadata);
    }

    /**
     * @notice Associate a new owner with a project
     * @param identityId ID of previously created project
     * @param newOwner address of new project owner
     */
    function addProjectOwner(uint256 identityId, address newOwner) external onlyProjectOwner(identityId) {
        require(newOwner != address(0) && newOwner != OWNERS_LIST_SENTINEL && newOwner != address(this), "PR001");

        OwnerList storage owners = identityOwners[identityId];

        require(owners.list[newOwner] == address(0), "PR002");

        owners.list[newOwner] = owners.list[OWNERS_LIST_SENTINEL];
        owners.list[OWNERS_LIST_SENTINEL] = newOwner;
        owners.count++;

        emit OwnerAdded(identityId, newOwner);
    }

    /**
     * @notice Disassociate an existing owner from a project
     * @param identityId ID of previously created project
     * @param prevOwner Address of previous owner in OwnerList
     * @param owner Address of new Owner
     */
    function removeProjectOwner(uint256 identityId, address prevOwner, address owner) external onlyProjectOwner(identityId) {
        require(owner != address(0) && owner != OWNERS_LIST_SENTINEL, "PR001");

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
     * @notice Retrieve count of existing project owners
     * @param identityId ID of project 
     * @return Count of owners for given project
     */
    function projectOwnersCount(uint256 identityId) external view returns(uint256) {
        return identityOwners[identityId].count;
    }

    /**
     * @notice Retrieve list of project owners 
     * @param identityId ID of project 
     * @return List of current owners of given project
     */
    function getProjectOwners(uint256 identityId) external view returns(address[] memory) {
        OwnerList storage owners = identityOwners[identityId];

        address[] memory list = new address[](owners.count);

        uint256 index = 0;
        address current = owners.list[OWNERS_LIST_SENTINEL];

        if (current == address(0x0)) {
            return list;
        }

        while (current != OWNERS_LIST_SENTINEL) {
            list[index] = current;
            current = owners.list[current];
            index++;
        }

        return list;
    }

    // Internal functions

    /**
     * @notice Create initial OwnerList for passed project
     * @param identityId ID of project
     */
    function initProjectOwners(uint256 identityId) internal {
        OwnerList storage owners = identityOwners[identityId];

        owners.list[OWNERS_LIST_SENTINEL] = msg.sender;
        owners.list[msg.sender] = OWNERS_LIST_SENTINEL;
        owners.count = 1;
    }

    // Private functions
    // ...
}

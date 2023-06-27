Quadratic Funding with Offchain Calculation Allocation Strategy
---------------------------------

## Overview 


Quadratic Funding is a category of mechanisms that distribute a funding pool based upon individual donations to eligible recipients. 
### Initialization

The `DirectGrants` contract requires initialization to set the necessary parameters. The initialization function `initialize` takes encoded parameters as input and sets the following:

* `pool`: The ID of the pool contract associated with the strategy.
* `allo`: The address of the allo contract.
* `approver`: The address of the committee member responsible for approving grant applications.
* Optional parameters can be included for application or allocation gating, such as the addresses of EAS (Enterprise Authentication Service), registry contract, or POH (Proof of Humanity) contract.

### Application Workflow

The Direct Grants allocation strategy supports the following workflow for applying for grants:

1. Users encode application data and call the `applyToPool` function, passing the encoded data and their address.
2. The encoded data is decoded to obtain the following:
    * `identityId`: The identity ID associated with the application.
    * `metaPtr`: A pointer to the metadata of the application.
    * `recipientAddress`: The address to receive the grant if the application is approved.
3. Custom logic can be implemented in the `applyToPool` function to gate applications based on additional checks, such as EAS, registry verification, or POH validation.
4. An application struct is created with the status set to `Pending` and the `allocatedAmount` set to 0.
5. The application struct is added to the `applications` mapping using the `identityId` as the key.
6. An event `ApplicationSubmitted` is emitted to signal the submission of the grant application.

### Allocation Workflow

The Direct Grants allocation strategy supports the following workflow for allocating funds:

1. Users encode allocation data and call the `allocate` function, passing the encoded data and their address.
2. The encoded data is decoded to obtain the following:
    * List of `identityId` representing the applicants.
    * Index of the application within the milestone.
3. The function checks if the application milestone is accepted by looking up the application status in the `applications` mapping.
4. The application status is updated to `Allocated`, and the `allocatedAmount` is set to the desired amount by the pool owner.
5. An event `ApplicationStatusSet` is emitted to indicate the updated status of the grant application.

### Payout Generation

The `generatePayouts` function in the Direct Grants allocation strategy is yet to be implemented. The TODO comments in the code suggest possible considerations for implementing the payout generation logic. The function might require collaboration with a distribution strategy to track and update the status of milestones to "Paid."

### Customization Options

The Direct Grants allocation strategy provides several functions to customize the strategy's behavior:

* `isClaimable()`: Returns a boolean value indicating whether this strategy is claimable. In this case, it always returns `false` to show that this strategy is not claimable.
* `reviewApplications(bytes[] memory _data)`: Allows the committee member (approver) to review multiple grant applications. The function decodes the data to obtain the `identityId`, `index` of the application within the milestone, and the desired `status`. It then updates the application status in the `applications` mapping.
* `transferOwnership(address newApprover)`: Allows the current approver to transfer the ownership of the committee to a new approver. The function checks if the sender is the current approver and updates the `approver` variable.

### Data Structures

The Direct Grants allocation strategy uses the following data structures:

* `MilestoneApplication`: A struct representing a grant application for a specific milestone. It contains the following fields:
    
    * `metaPtr`: A pointer to the metadata of the application.
    * `identityId`: The identity ID associated with the application.
    * `recipientAddress`: The address to receive the grant if the application is approved.
    * `allocatedAmount`: The amount allocated to the grant application by the pool owner during the allocation process.
    * `status`: The status of the grant application, which can be one of the following:
        * `None`: Initial status before the application is submitted.
        * `Pending`: Status indicating the application is pending review by the committee.
        * `Accepted`: Status indicating the application has been accepted by the committee.
        * `Rejected`: Status indicating the application has been rejected by the committee.
        * `Allocated`: Status indicating the grant has been allocated by the pool owner.
* `applications`: A mapping that associates an address (identityId) with an array of `MilestoneApplication` structs. It stores the grant applications submitted for different milestones.
    

### Events

The Direct Grants allocation strategy emits the following events:

* `ApplicationSubmitted`: An event emitted when a grant application is submitted. It includes the following information:
    
    * `id`: The indexed ID of the application.
    * `applicant`: The indexed address of the applicant.
    * `status`: The status of the application.
* `ApplicationStatusSet`: An event emitted when the status of a grant application is updated. It includes the following information:
    
    * `id`: The indexed ID of the application.
    * `applicant`: The indexed address of the applicant.
    * `status`: The new status of the application.

#### New Variables
```javascript

struct Application {
    MetaPtr metaPtr;
    address identityId;
    address recipientAddress;
    uint256 requestedAmount;
    ApplicationStatus status;
}

// stores mapping from identityId -> Application
mapping (address => Application[]) public applications;

```

#### New Functions

Functions around actual functionality

```javascript

function isClaimable() external pure returns (bool) {
    // To show that this strategy is not claimable
    return false;
}

function reviewApplications(bytes[] memory _data) external {
    // decode data to get list of 
    //  - identityId
    //  - index of application (to know which milestone)
    //  - status
    
    // update application status in applications mapping
}
```


### Open Questions

- Is there an application period ? 
- Are we intending to have committee different from pool owner ? When are these committee owners set ?
- Update IAllocationStrategy.allocate to accept msg.sender as argument (set by IAllo)
- Question to product: When i submit a milestone application ->
    - do i request amount to be paid
    - or is it pre-determined
- generatePayout would have to be updated to accept argument to specify which milestone should be paid out

## Variations

The allocation strategy can be customized for different usecase

- Application Gating 
    - update initialize() (if applicable)
    - update applyToPool to invoke contracts to check gating
- Allocation Gating
    - allocators could have SBT/ EAS
    - allocator could just be pool owners
- Not using registry. AKA no indentityId 
    - in these cases, an applicationID would have to be generated by the AllocationStrategys
| contracts/core/Allo.sol:Allo contract |                 |         |        |         |         |
|---------------------------------------|-----------------|---------|--------|---------|---------|
| Deployment Cost                       | Deployment Size |         |        |         |         |
| 2982877                               | 13634           |         |        |         |         |
| Function Name                         | min             | avg     | median | max     | # calls |
| addPoolManager                        | 26358           | 35397   | 26531  | 53304   | 3       |
| addPoolManagers                       | 26559           | 1498895 | 116150 | 6509907 | 1024    |
| allocate                              | 38534           | 87818   | 75130  | 187732  | 78      |
| batchAllocate                         | 46074           | 77370   | 77370  | 108666  | 2       |
| batchRegisterRecipient                | 46573           | 78349   | 78349  | 110126  | 2       |
| createPool                            | 49070           | 526533  | 541491 | 541491  | 51      |
| createPoolWithCustomStrategy          | 26948           | 403451  | 346947 | 573094  | 2190    |
| distribute                            | 65408           | 135067  | 167627 | 167627  | 9       |
| fundPool                              | 43858           | 132336  | 136003 | 162034  | 171     |
| getBaseFee                            | 372             | 372     | 372    | 372     | 2       |
| getPercentFee                         | 382             | 382     | 382    | 382     | 2       |
| getPool                               | 2944            | 10582   | 12944  | 16944   | 216     |
| getRegistry                           | 398             | 983     | 398    | 2398    | 1237    |
| getStrategy                           | 550             | 550     | 550    | 550     | 42      |
| getTreasury                           | 399             | 399     | 399    | 399     | 2       |
| initialize                            | 25595           | 143473  | 143574 | 163546  | 980     |
| isPoolAdmin                           | 950             | 1950    | 1950   | 2950    | 2       |
| isPoolManager                         | 999             | 2801    | 3488   | 9488    | 118833  |
| recoverFunds                          | 24158           | 45301   | 52832  | 58913   | 3       |
| registerRecipient                     | 54289           | 161046  | 183137 | 203037  | 48      |
| removePoolManager                     | 26574           | 28944   | 28944  | 31315   | 2       |
| removePoolManagers                    | 26569           | 411198  | 105580 | 1692596 | 512     |
| transferOwnership                     | 28567           | 28567   | 28567  | 28567   | 50      |
| updateBaseFee                         | 23708           | 41126   | 46933  | 46933   | 4       |
| updatePercentFee                      | 23670           | 24995   | 24985  | 29857   | 234     |
| updatePoolMetadata                    | 32107           | 37390   | 37390  | 42674   | 2       |
| updateRegistry                        | 23800           | 25954   | 23942  | 30121   | 3       |
| updateTreasury                        | 23821           | 25979   | 23963  | 30153   | 3       |


| contracts/core/Registry.sol:Registry contract |                 |                     |        |                     |         |
|-----------------------------------------------|-----------------|---------------------|--------|---------------------|---------|
| Deployment Cost                               | Deployment Size |                     |        |                     |         |
| 2613524                                       | 11958           |                     |        |                     |         |
| Function Name                                 | min             | avg                 | median | max                 | # calls |
| ALLO_OWNER                                    | 284             | 284                 | 284    | 284                 | 1       |
| acceptProfileOwnership                        | 24178           | 25801               | 24178  | 29047               | 3       |
| addMembers                                    | 25322           | 49393               | 50109  | 75370               | 67      |
| anchorToProfileId                             | 608             | 608                 | 608    | 608                 | 4       |
| createProfile                                 | 28412           | 723874              | 723897 | 853983              | 2972    |
| getProfileByAnchor                            | 4071            | 20282               | 20071  | 37535               | 369     |
| getProfileById                                | 3776            | 3780                | 3776   | 5240                | 2952    |
| hasRole                                       | 743             | 743                 | 743    | 743                 | 1       |
| initialize                                    | 44040           | 70051               | 70077  | 70077               | 1018    |
| isMemberOfProfile                             | 816             | 1649                | 816    | 2816                | 12      |
| isOwnerOfProfile                              | 713             | 713                 | 713    | 713                 | 7       |
| isOwnerOrMemberOfProfile                      | 0               | 2604                | 2696   | 5016                | 2609    |
| profileIdToPendingOwner                       | 523             | 523                 | 523    | 523                 | 3       |
| recoverFunds                                  | 24258           | 40909               | 40104  | 59171               | 4       |
| removeMembers                                 | 25894           | 28804               | 28311  | 32702               | 4       |
| updateProfileMetadata                         | 25624           | 29151               | 25636  | 36195               | 3       |
| updateProfileName                             | 25044           | 2553540988718952275 | 545402 | 8937393460515995998 | 7       |
| updateProfilePendingOwner                     | 24613           | 42352               | 48265  | 48265               | 4       |


| contracts/factories/ContractFactory.sol:ContractFactory contract |                 |        |        |        |         |
|------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                  | Deployment Size |        |        |        |         |
| 381784                                                           | 1483            |        |        |        |         |
| Function Name                                                    | min             | avg    | median | max    | # calls |
| deploy                                                           | 67918           | 353831 | 354513 | 638380 | 4       |
| isDeployer                                                       | 530             | 2030   | 2530   | 2530   | 4       |
| setDeployer                                                      | 24207           | 43626  | 46401  | 46401  | 8       |


| contracts/strategies/_poc/qv-impact-stream/QVImpactStreamStrategy.sol:QVImpactStreamStrategy contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                                       | Deployment Size |        |        |        |         |
| 2677951                                                                                               | 12791           |        |        |        |         |
| Function Name                                                                                         | min             | avg    | median | max    | # calls |
| addAllocator                                                                                          | 36195           | 45783  | 45783  | 55372  | 2       |
| allocationEndTime                                                                                     | 420             | 420    | 420    | 420    | 3       |
| allocationStartTime                                                                                   | 414             | 1747   | 2414   | 2414   | 3       |
| batchAddAllocator                                                                                     | 37312           | 83631  | 84840  | 84840  | 43      |
| batchRemoveAllocator                                                                                  | 36877           | 37060  | 37060  | 37243  | 2       |
| getAllo                                                                                               | 315             | 315    | 315    | 315    | 42      |
| getPayouts                                                                                            | 27217           | 27217  | 27217  | 27217  | 1       |
| getPoolId                                                                                             | 393             | 393    | 393    | 393    | 42      |
| getRecipient                                                                                          | 3519            | 3852   | 3519   | 5519   | 6       |
| getRecipientStatus                                                                                    | 4693            | 4693   | 4693   | 4693   | 1       |
| getVoiceCreditsCastByAllocator                                                                        | 610             | 610    | 610    | 610    | 2       |
| getVoiceCreditsCastByAllocatorToRecipient                                                             | 784             | 784    | 784    | 784    | 4       |
| getVotesCastByAllocatorToRecipient                                                                    | 807             | 807    | 807    | 807    | 4       |
| initialize                                                                                            | 30284           | 89859  | 115215 | 120606 | 5       |
| isPoolActive                                                                                          | 671             | 1670   | 1670   | 2670   | 2       |
| isValidAllocator                                                                                      | 667             | 1667   | 1667   | 2667   | 12      |
| maxVoiceCreditsPerAllocator                                                                           | 2396            | 2396   | 2396   | 2396   | 2       |
| payouts                                                                                               | 613             | 613    | 613    | 613    | 2       |
| recoverFunds                                                                                          | 36711           | 54747  | 60822  | 66708  | 3       |
| removeAllocator                                                                                       | 33432           | 34802  | 34802  | 36172  | 2       |
| setPayouts                                                                                            | 35989           | 105941 | 137944 | 140971 | 11      |
| updatePoolTimestamps                                                                                  | 32050           | 35749  | 36436  | 38763  | 3       |


| contracts/strategies/_poc/sqf-superfluid/RecipientSuperApp.sol:RecipientSuperApp contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                           | Deployment Size |        |        |        |         |
| 0                                                                                         | 0               |        |        |        |         |
| Function Name                                                                             | min             | avg    | median | max    | # calls |
| acceptedToken                                                                             | 284             | 284    | 284    | 284    | 1       |
| beforeAgreementTerminated                                                                 | 13870           | 13870  | 13870  | 13870  | 3       |
| beforeAgreementUpdated                                                                    | 13877           | 13877  | 13877  | 13877  | 1       |
| closeIncomingStream                                                                       | 23968           | 308033 | 308033 | 592099 | 2       |
| emergencyWithdraw                                                                         | 23947           | 205538 | 205538 | 387130 | 2       |
| recipient                                                                                 | 426             | 426    | 426    | 426    | 1       |
| strategy                                                                                  | 238             | 238    | 238    | 238    | 1       |


| contracts/strategies/_poc/sqf-superfluid/SQFSuperFluidStrategy.sol:SQFSuperFluidStrategy contract |                 |         |         |         |         |
|---------------------------------------------------------------------------------------------------|-----------------|---------|---------|---------|---------|
| Deployment Cost                                                                                   | Deployment Size |         |         |         |         |
| 3869257                                                                                           | 18232           |         |         |         |         |
| Function Name                                                                                     | min             | avg     | median  | max     | # calls |
| adjustWeightings                                                                                  | 23914           | 23914   | 23914   | 23914   | 1       |
| allocationEndTime                                                                                 | 420             | 420     | 420     | 420     | 2       |
| allocationStartTime                                                                               | 420             | 420     | 420     | 420     | 2       |
| allocationSuperToken                                                                              | 395             | 395     | 395     | 395     | 1       |
| cancelRecipients                                                                                  | 44032           | 184875  | 184875  | 325718  | 2       |
| closeStream                                                                                       | 862115          | 862115  | 862115  | 862115  | 1       |
| gdaPool                                                                                           | 439             | 439     | 439     | 439     | 3       |
| getAllo                                                                                           | 271             | 271     | 271     | 271     | 48      |
| getPayouts                                                                                        | 3103            | 3103    | 3103    | 3103    | 1       |
| getPoolId                                                                                         | 382             | 382     | 382     | 382     | 48      |
| getRecipient                                                                                      | 3069            | 3640    | 3069    | 5069    | 14      |
| getRecipientStatus                                                                                | 2346            | 2346    | 2346    | 2346    | 1       |
| getStrategyId                                                                                     | 260             | 260     | 260     | 260     | 1       |
| getSuperApp                                                                                       | 667             | 667     | 667     | 667     | 4       |
| initialSuperAppBalance                                                                            | 362             | 362     | 362     | 362     | 1       |
| isValidAllocator                                                                                  | 1590            | 1590    | 1590    | 1590    | 15      |
| metadataRequired                                                                                  | 432             | 432     | 432     | 432     | 1       |
| minPassportScore                                                                                  | 407             | 407     | 407     | 407     | 2       |
| passportDecoder                                                                                   | 394             | 394     | 394     | 394     | 1       |
| recipientFlowRate                                                                                 | 581             | 581     | 581     | 581     | 13      |
| registrationEndTime                                                                               | 413             | 413     | 413     | 413     | 2       |
| registrationStartTime                                                                             | 381             | 381     | 381     | 381     | 2       |
| reviewRecipients                                                                                  | 42262           | 2084241 | 2358406 | 4475869 | 26      |
| superfluidHost                                                                                    | 416             | 416     | 416     | 416     | 1       |
| totalUnitsByRecipient                                                                             | 604             | 604     | 604     | 604     | 15      |
| updateMinPassportScore                                                                            | 45131           | 45131   | 45131   | 45131   | 1       |
| updatePoolTimestamps                                                                              | 39868           | 43559   | 43559   | 47251   | 2       |
| useRegistryAnchor                                                                                 | 400             | 400     | 400     | 400     | 1       |
| withdraw                                                                                          | 41460           | 51545   | 43785   | 69390   | 3       |


| contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol:DonationVotingMerkleDistributionDirectTransferStrategy contract |                 |        |        |        |         |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                                                                                                                                     | Deployment Size |        |        |        |         |
| 3790978                                                                                                                                                                                             | 18140           |        |        |        |         |
| Function Name                                                                                                                                                                                       | min             | avg    | median | max    | # calls |
| allocationEndTime                                                                                                                                                                                   | 404             | 1404   | 1404   | 2404   | 2       |
| allocationStartTime                                                                                                                                                                                 | 441             | 441    | 441    | 441    | 2       |
| allowedTokens                                                                                                                                                                                       | 2592            | 2592   | 2592   | 2592   | 1       |
| distribute                                                                                                                                                                                          | 41422           | 124650 | 157119 | 178778 | 8       |
| getAllo                                                                                                                                                                                             | 293             | 293    | 293    | 293    | 54      |
| getPayouts                                                                                                                                                                                          | 19539           | 19539  | 19539  | 19539  | 1       |
| getPoolId                                                                                                                                                                                           | 393             | 430    | 393    | 2393   | 54      |
| getRecipient                                                                                                                                                                                        | 2559            | 2559   | 2559   | 2559   | 1       |
| getRecipientStatus                                                                                                                                                                                  | 1612            | 1612   | 1612   | 1612   | 2       |
| getStrategyId                                                                                                                                                                                       | 250             | 250    | 250    | 250    | 1       |
| hasBeenDistributed                                                                                                                                                                                  | 739             | 1739   | 1739   | 2739   | 2       |
| initialize                                                                                                                                                                                          | 25211           | 27295  | 27295  | 29380  | 2       |
| isDistributionSet                                                                                                                                                                                   | 372             | 1372   | 1372   | 2372   | 2       |
| isPoolActive                                                                                                                                                                                        | 627             | 1559   | 1559   | 2492   | 2       |
| isValidAllocator                                                                                                                                                                                    | 477             | 477    | 477    | 477    | 2       |
| metadataRequired                                                                                                                                                                                    | 410             | 410    | 410    | 410    | 1       |
| recipientsCounter                                                                                                                                                                                   | 352             | 352    | 352    | 352    | 20      |
| registerRecipient                                                                                                                                                                                   | 28572           | 159384 | 181417 | 181417 | 33      |
| registrationEndTime                                                                                                                                                                                 | 420             | 420    | 420    | 420    | 2       |
| registrationStartTime                                                                                                                                                                               | 414             | 414    | 414    | 414    | 2       |
| reviewRecipients                                                                                                                                                                                    | 24864           | 46948  | 48592  | 48592  | 20      |
| statusesBitMap                                                                                                                                                                                      | 537             | 537    | 537    | 537    | 1       |
| updateDistribution                                                                                                                                                                                  | 25083           | 92869  | 111939 | 111939 | 12      |
| updatePoolTimestamps                                                                                                                                                                                | 36928           | 39526  | 37066  | 49496  | 5       |
| useRegistryAnchor                                                                                                                                                                                   | 2378            | 2378   | 2378   | 2378   | 1       |
| withdraw                                                                                                                                                                                            | 36465           | 48704  | 38705  | 70943  | 3       |


| contracts/strategies/donation-voting-merkle-distribution-vault/DonationVotingMerkleDistributionVaultStrategy.sol:DonationVotingMerkleDistributionVaultStrategy contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                                                                                                         | Deployment Size |        |        |        |         |
| 3569897                                                                                                                                                                 | 17113           |        |        |        |         |
| Function Name                                                                                                                                                           | min             | avg    | median | max    | # calls |
| allocationEndTime                                                                                                                                                       | 404             | 1404   | 1404   | 2404   | 2       |
| allocationStartTime                                                                                                                                                     | 441             | 441    | 441    | 441    | 2       |
| allowedTokens                                                                                                                                                           | 2592            | 2592   | 2592   | 2592   | 1       |
| claim                                                                                                                                                                   | 46905           | 65303  | 56722  | 92282  | 3       |
| claims                                                                                                                                                                  | 787             | 787    | 787    | 787    | 2       |
| distribute                                                                                                                                                              | 41432           | 124583 | 157032 | 178668 | 8       |
| getAllo                                                                                                                                                                 | 271             | 271    | 271    | 271    | 57      |
| getPayouts                                                                                                                                                              | 19510           | 19510  | 19510  | 19510  | 1       |
| getPoolId                                                                                                                                                               | 371             | 406    | 371    | 2371   | 57      |
| getRecipient                                                                                                                                                            | 2559            | 2559   | 2559   | 2559   | 1       |
| getRecipientStatus                                                                                                                                                      | 1612            | 1612   | 1612   | 1612   | 2       |
| getStrategyId                                                                                                                                                           | 250             | 250    | 250    | 250    | 1       |
| hasBeenDistributed                                                                                                                                                      | 739             | 1739   | 1739   | 2739   | 2       |
| initialize                                                                                                                                                              | 25202           | 27284  | 27284  | 29367  | 2       |
| isDistributionSet                                                                                                                                                       | 395             | 1395   | 1395   | 2395   | 2       |
| isPoolActive                                                                                                                                                            | 627             | 1559   | 1559   | 2492   | 2       |
| isValidAllocator                                                                                                                                                        | 477             | 477    | 477    | 477    | 2       |
| metadataRequired                                                                                                                                                        | 388             | 388    | 388    | 388    | 1       |
| recipientsCounter                                                                                                                                                       | 352             | 352    | 352    | 352    | 23      |
| registerRecipient                                                                                                                                                       | 28541           | 161141 | 181337 | 181337 | 36      |
| registrationEndTime                                                                                                                                                     | 420             | 420    | 420    | 420    | 2       |
| registrationStartTime                                                                                                                                                   | 414             | 414    | 414    | 414    | 2       |
| reviewRecipients                                                                                                                                                        | 24861           | 47160  | 48589  | 48589  | 23      |
| statusesBitMap                                                                                                                                                          | 537             | 537    | 537    | 537    | 1       |
| updateDistribution                                                                                                                                                      | 25120           | 92906  | 111976 | 111976 | 12      |
| updatePoolTimestamps                                                                                                                                                    | 36906           | 39504  | 37044  | 49474  | 5       |
| useRegistryAnchor                                                                                                                                                       | 2378            | 2378   | 2378   | 2378   | 1       |
| withdraw                                                                                                                                                                | 36465           | 55655  | 55929  | 74298  | 4       |


| contracts/strategies/qv-simple/QVSimpleStrategy.sol:QVSimpleStrategy contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                               | Deployment Size |        |        |        |         |
| 3077527                                                                       | 14652           |        |        |        |         |
| Function Name                                                                 | min             | avg    | median | max    | # calls |
| addAllocator                                                                  | 35647           | 49496  | 40136  | 60036  | 112     |
| allocate                                                                      | 27888           | 100589 | 157784 | 157784 | 13      |
| allocationEndTime                                                             | 420             | 420    | 420    | 420    | 2       |
| allocationStartTime                                                           | 397             | 397    | 397    | 397    | 2       |
| distribute                                                                    | 57394           | 121068 | 129760 | 147162 | 6       |
| getAllo                                                                       | 315             | 315    | 315    | 315    | 54      |
| getPayouts                                                                    | 4745            | 14726  | 14726  | 24707  | 2       |
| getPoolId                                                                     | 393             | 430    | 393    | 2393   | 54      |
| getRecipient                                                                  | 3269            | 3935   | 3269   | 5269   | 3       |
| getRecipientStatus                                                            | 2534            | 4716   | 4534   | 14360  | 10      |
| getStrategyId                                                                 | 249             | 249    | 249    | 249    | 1       |
| increasePoolAmount                                                            | 23855           | 23855  | 23855  | 23855  | 1       |
| initialize                                                                    | 23532           | 124322 | 125560 | 125560 | 263     |
| isPoolActive                                                                  | 634             | 1569   | 1569   | 2505   | 2       |
| isValidAllocator                                                              | 2667            | 2667   | 2667   | 2667   | 3       |
| maxVoiceCreditsPerAllocator                                                   | 2396            | 2396   | 2396   | 2396   | 1       |
| metadataRequired                                                              | 2389            | 2389   | 2389   | 2389   | 1       |
| registerRecipient                                                             | 23932           | 119624 | 148448 | 148448 | 30      |
| registrationEndTime                                                           | 435             | 435    | 435    | 435    | 2       |
| registrationStartTime                                                         | 381             | 1381   | 1381   | 2381   | 2       |
| removeAllocator                                                               | 35631           | 36015  | 36015  | 36400  | 2       |
| reviewRecipients                                                              | 34862           | 78355  | 78038  | 92436  | 50      |
| reviewsByStatus                                                               | 803             | 803    | 803    | 803    | 7       |
| updatePoolTimestamps                                                          | 36920           | 39491  | 37045  | 44509  | 3       |
| withdraw                                                                      | 38677           | 43973  | 43973  | 49270  | 2       |


| contracts/strategies/rfp-committee/RFPCommitteeStrategy.sol:RFPCommitteeStrategy contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                           | Deployment Size |        |        |        |         |
| 2862107                                                                                   | 13579           |        |        |        |         |
| Function Name                                                                             | min             | avg    | median | max    | # calls |
| allocate                                                                                  | 22980           | 72231  | 86060  | 94963  | 8       |
| getAllo                                                                                   | 260             | 260    | 260    | 260    | 9       |
| getPoolId                                                                                 | 349             | 349    | 349    | 349    | 9       |
| getRecipientStatus                                                                        | 2758            | 2758   | 2758   | 2758   | 1       |
| getStrategyId                                                                             | 282             | 282    | 282    | 282    | 1       |
| initialize                                                                                | 23590           | 94644  | 95175  | 164637 | 4       |
| maxBid                                                                                    | 406             | 406    | 406    | 406    | 1       |
| metadataRequired                                                                          | 410             | 410    | 410    | 410    | 1       |
| registerRecipient                                                                         | 178095          | 190911 | 195183 | 195183 | 4       |
| setMilestones                                                                             | 131769          | 131769 | 131769 | 131769 | 3       |
| useRegistryAnchor                                                                         | 377             | 377    | 377    | 377    | 1       |
| voteThreshold                                                                             | 385             | 385    | 385    | 385    | 1       |
| votedFor                                                                                  | 629             | 629    | 629    | 629    | 2       |
| votes                                                                                     | 624             | 1290   | 624    | 2624   | 6       |


| contracts/strategies/rfp-simple/RFPSimpleStrategy.sol:RFPSimpleStrategy contract |                 |        |        |        |         |
|----------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                  | Deployment Size |        |        |        |         |
| 2797636                                                                          | 13272           |        |        |        |         |
| Function Name                                                                    | min             | avg    | median | max    | # calls |
| allocate                                                                         | 23208           | 63738  | 68925  | 68925  | 22      |
| distribute                                                                       | 23327           | 98310  | 99489  | 141589 | 11      |
| getAllo                                                                          | 260             | 260    | 260    | 260    | 53      |
| getMilestone                                                                     | 2541            | 2541   | 2541   | 2541   | 5       |
| getMilestoneStatus                                                               | 754             | 754    | 754    | 754    | 2       |
| getPayouts                                                                       | 3683            | 3683   | 3683   | 3683   | 1       |
| getPoolId                                                                        | 371             | 371    | 371    | 371    | 53      |
| getRecipient                                                                     | 3295            | 4773   | 3295   | 13354  | 7       |
| getRecipientStatus                                                               | 2539            | 2615   | 2615   | 2691   | 2       |
| getStrategyId                                                                    | 304             | 304    | 304    | 304    | 1       |
| increaseMaxBid                                                                   | 36174           | 38898  | 38251  | 42270  | 3       |
| initialize                                                                       | 23259           | 102683 | 141862 | 141874 | 6       |
| isPoolActive                                                                     | 393             | 393    | 393    | 393    | 1       |
| isValidAllocator                                                                 | 6578            | 10828  | 10828  | 15078  | 2       |
| maxBid                                                                           | 341             | 341    | 341    | 341    | 2       |
| metadataRequired                                                                 | 366             | 366    | 366    | 366    | 1       |
| registerRecipient                                                                | 28429           | 163370 | 195116 | 225810 | 33      |
| rejectMilestone                                                                  | 36145           | 41629  | 40511  | 45490  | 5       |
| setMilestones                                                                    | 36643           | 178228 | 203838 | 203838 | 22      |
| setPoolActive                                                                    | 36164           | 37038  | 37475  | 37475  | 3       |
| submitUpcomingMilestone                                                          | 28647           | 54910  | 57135  | 57135  | 14      |
| useRegistryAnchor                                                                | 399             | 399    | 399    | 399    | 1       |
| withdraw                                                                         | 36394           | 48545  | 38540  | 70703  | 3       |




Ran 30 test suites in 3.95s (5.53s CPU time): 1085 tests passed, 0 failed, 0 skipped (1085 total tests)

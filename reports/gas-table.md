| contracts/core/Allo.sol:Allo contract |                 |        |        |        |         |
|---------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                       | Deployment Size |        |        |        |         |
| 2748792                               | 13761           |        |        |        |         |
| Function Name                         | min             | avg    | median | max    | # calls |
| addPoolManager                        | 1005            | 9220   | 2959   | 23698  | 3       |
| addToCloneableStrategies              | 2531            | 23048  | 23861  | 25861  | 45      |
| allocate                              | 5234            | 54757  | 40032  | 138575 | 47      |
| batchAllocate                         | 23629           | 48191  | 48191  | 72753  | 2       |
| batchRegisterRecipient                | 24157           | 49199  | 49199  | 74242  | 2       |
| createPool                            | 26687           | 464014 | 478535 | 478535 | 44      |
| createPoolWithCustomStrategy          | 2364            | 433361 | 433228 | 533340 | 704     |
| distribute                            | 14075           | 72808  | 92781  | 92781  | 9       |
| fundPool                              | 22548           | 93781  | 92121  | 121964 | 137     |
| getBaseFee                            | 394             | 394    | 394    | 394    | 2       |
| getPercentFee                         | 404             | 404    | 404    | 404    | 2       |
| getPool                               | 2921            | 6250   | 2921   | 16921  | 179     |
| getRegistry                           | 420             | 666    | 420    | 2420   | 754     |
| getStrategy                           | 572             | 572    | 572    | 572    | 42      |
| getTreasury                           | 399             | 399    | 399    | 399    | 2       |
| initialize                            | 3051            | 120985 | 121113 | 141013 | 771     |
| isCloneableStrategy                   | 634             | 1134   | 634    | 2634   | 4       |
| isPoolAdmin                           | 972             | 1972   | 1972   | 2972   | 2       |
| isPoolManager                         | 999             | 5092   | 3488   | 9488   | 948     |
| recoverFunds                          | 2610            | 19544  | 21399  | 34625  | 3       |
| registerRecipient                     | 9007            | 134319 | 157607 | 182224 | 48      |
| removeFromCloneableStrategies         | 1529            | 2031   | 2031   | 2533   | 2       |
| removePoolManager                     | 2995            | 2998   | 2998   | 3002   | 2       |
| transferOwnership                     | 2335            | 2335   | 2335   | 2335   | 51      |
| updateBaseFee                         | 2456            | 19865  | 25669  | 25669  | 4       |
| updatePercentFee                      | 1355            | 1404   | 1355   | 8593   | 193     |
| updatePoolMetadata                    | 5981            | 6814   | 6814   | 7648   | 2       |
| updateRegistry                        | 2532            | 4628   | 2630   | 8722   | 3       |
| updateTreasury                        | 2531            | 4627   | 2629   | 8721   | 3       |


| contracts/core/Registry.sol:Registry contract |                 |                     |        |                     |         |
|-----------------------------------------------|-----------------|---------------------|--------|---------------------|---------|
| Deployment Cost                               | Deployment Size |                     |        |                     |         |
| 2387760                                       | 11958           |                     |        |                     |         |
| Function Name                                 | min             | avg                 | median | max                 | # calls |
| ALLO_OWNER                                    | 284             | 284                 | 284    | 284                 | 1       |
| acceptProfileOwnership                        | 602             | 1780                | 2137   | 2602                | 3       |
| addMembers                                    | 1325            | 25149               | 25909  | 46778               | 67      |
| anchorToProfileId                             | 608             | 608                 | 608    | 608                 | 4       |
| createProfile                                 | 2627            | 699935              | 700009 | 830027              | 2345    |
| getProfileByAnchor                            | 3585            | 15312               | 19585  | 20071               | 270     |
| getProfileById                                | 3776            | 3782                | 3776   | 5240                | 2325    |
| hasRole                                       | 743             | 743                 | 743    | 743                 | 1       |
| initialize                                    | 22848           | 48613               | 48645  | 48645               | 809     |
| isMemberOfProfile                             | 816             | 1649                | 816    | 2816                | 12      |
| isOwnerOfProfile                              | 713             | 713                 | 713    | 713                 | 7       |
| isOwnerOrMemberOfProfile                      | 0               | 966                 | 696    | 5016                | 988     |
| profileIdToPendingOwner                       | 523             | 523                 | 523    | 523                 | 3       |
| recoverFunds                                  | 2914            | 16688               | 14478  | 34883               | 4       |
| removeMembers                                 | 1302            | 3022                | 2719   | 5348                | 4       |
| updateProfileMetadata                         | 1228            | 3114                | 3228   | 4887                | 3       |
| updateProfileName                             | 976             | 2553540988718927679 | 491722 | 8937393460515998189 | 7       |
| updateProfilePendingOwner                     | 669             | 18408               | 24321  | 24321               | 4       |


| contracts/factory/ContractFactory.sol:ContractFactory contract |                 |        |        |        |         |
|----------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                | Deployment Size |        |        |        |         |
| 306928                                                         | 1483            |        |        |        |         |
| Function Name                                                  | min             | avg    | median | max    | # calls |
| deploy                                                         | 2891            | 289075 | 289393 | 574624 | 4       |
| isDeployer                                                     | 530             | 2030   | 2530   | 2530   | 4       |
| setDeployer                                                    | 2635            | 20304  | 22829  | 22829  | 8       |


| contracts/strategies/_poc/qv-impact-stream/QVImpactStreamStrategy.sol:QVImpactStreamStrategy contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                                       | Deployment Size |        |        |        |         |
| 2380139                                                                                               | 12534           |        |        |        |         |
| Function Name                                                                                         | min             | avg    | median | max    | # calls |
| addAllocator                                                                                          | 14950           | 23538  | 23538  | 32127  | 2       |
| allocate                                                                                              | 3245            | 26656  | 10624  | 108753 | 10      |
| allocationEndTime                                                                                     | 436             | 436    | 436    | 436    | 3       |
| allocationStartTime                                                                                   | 358             | 1691   | 2358   | 2358   | 3       |
| batchAddAllocator                                                                                     | 15601           | 51861  | 52677  | 54688  | 43      |
| batchRemoveAllocator                                                                                  | 15557           | 15942  | 15942  | 16328  | 2       |
| distribute                                                                                            | 43588           | 56251  | 56251  | 68915  | 2       |
| getAllo                                                                                               | 315             | 315    | 315    | 315    | 41      |
| getPayouts                                                                                            | 24697           | 24697  | 24697  | 24697  | 1       |
| getPoolId                                                                                             | 327             | 327    | 327    | 327    | 41      |
| getRecipient                                                                                          | 3172            | 3505   | 3172   | 5172   | 6       |
| getRecipientStatus                                                                                    | 4461            | 4461   | 4461   | 4461   | 1       |
| getVoiceCreditsCastByAllocator                                                                        | 610             | 610    | 610    | 610    | 2       |
| getVoiceCreditsCastByAllocatorToRecipient                                                             | 784             | 784    | 784    | 784    | 4       |
| getVotesCastByAllocatorToRecipient                                                                    | 829             | 829    | 829    | 829    | 4       |
| increasePoolAmount                                                                                    | 22629           | 22629  | 22629  | 22629  | 41      |
| initialize                                                                                            | 5560            | 90658  | 95195  | 97195  | 46      |
| isPoolActive                                                                                          | 657             | 1656   | 1656   | 2656   | 2       |
| isValidAllocator                                                                                      | 644             | 1644   | 1644   | 2644   | 12      |
| maxVoiceCreditsPerAllocator                                                                           | 2352            | 2352   | 2352   | 2352   | 2       |
| payouts                                                                                               | 613             | 613    | 613    | 613    | 2       |
| receive                                                                                               | 55              | 55     | 55     | 55     | 41      |
| recoverFunds                                                                                          | 15029           | 29789  | 29312  | 45026  | 3       |
| registerRecipient                                                                                     | 16903           | 136552 | 153113 | 153113 | 28      |
| removeAllocator                                                                                       | 11992           | 13460  | 13460  | 14929  | 2       |
| setPayouts                                                                                            | 3225            | 59630  | 82431  | 85483  | 11      |
| updatePoolTimestamps                                                                                  | 10619           | 14310  | 15005  | 17307  | 3       |


| contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol:DonationVotingMerkleDistributionDirectTransferStrategy contract |                 |        |        |        |         |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                                                                                                                                     | Deployment Size |        |        |        |         |
| 3029610                                                                                                                                                                                             | 15862           |        |        |        |         |
| Function Name                                                                                                                                                                                       | min             | avg    | median | max    | # calls |
| allocate                                                                                                                                                                                            | 5311            | 25806  | 13452  | 63688  | 9       |
| allocationEndTime                                                                                                                                                                                   | 381             | 1381   | 1381   | 2381   | 2       |
| allocationStartTime                                                                                                                                                                                 | 441             | 441    | 441    | 441    | 2       |
| allowedTokens                                                                                                                                                                                       | 2592            | 2592   | 2592   | 2592   | 1       |
| distribute                                                                                                                                                                                          | 7239            | 73154  | 98246  | 117471 | 8       |
| getAllo                                                                                                                                                                                             | 293             | 293    | 293    | 293    | 51      |
| getPayouts                                                                                                                                                                                          | 19487           | 19487  | 19487  | 19487  | 1       |
| getPoolId                                                                                                                                                                                           | 393             | 432    | 393    | 2393   | 51      |
| getRecipient                                                                                                                                                                                        | 2581            | 2581   | 2581   | 2581   | 1       |
| getRecipientStatus                                                                                                                                                                                  | 1612            | 1612   | 1612   | 1612   | 2       |
| getStrategyId                                                                                                                                                                                       | 227             | 227    | 227    | 227    | 1       |
| hasBeenDistributed                                                                                                                                                                                  | 761             | 1761   | 1761   | 2761   | 2       |
| increasePoolAmount                                                                                                                                                                                  | 5507            | 20774  | 22607  | 22607  | 56      |
| initialize                                                                                                                                                                                          | 926             | 139976 | 145461 | 145461 | 52      |
| isDistributionSet                                                                                                                                                                                   | 372             | 1372   | 1372   | 2372   | 2       |
| isPoolActive                                                                                                                                                                                        | 627             | 1559   | 1559   | 2492   | 2       |
| isValidAllocator                                                                                                                                                                                    | 499             | 499    | 499    | 499    | 2       |
| metadataRequired                                                                                                                                                                                    | 410             | 410    | 410    | 410    | 1       |
| receive                                                                                                                                                                                             | 55              | 55     | 55     | 55     | 56      |
| recipientsCounter                                                                                                                                                                                   | 374             | 374    | 374    | 374    | 18      |
| registerRecipient                                                                                                                                                                                   | 5331            | 125489 | 155627 | 155627 | 31      |
| registrationEndTime                                                                                                                                                                                 | 420             | 420    | 420    | 420    | 2       |
| registrationStartTime                                                                                                                                                                               | 436             | 436    | 436    | 436    | 2       |
| reviewRecipients                                                                                                                                                                                    | 3109            | 14627  | 15437  | 15437  | 18      |
| statusesBitMap                                                                                                                                                                                      | 537             | 537    | 537    | 537    | 1       |
| updateDistribution                                                                                                                                                                                  | 3121            | 59587  | 73093  | 89593  | 12      |
| updatePoolTimestamps                                                                                                                                                                                | 15268           | 18584  | 15405  | 25081  | 3       |
| useRegistryAnchor                                                                                                                                                                                   | 2400            | 2400   | 2400   | 2400   | 1       |
| withdraw                                                                                                                                                                                            | 14989           | 27228  | 17229  | 49467  | 3       |


| contracts/strategies/donation-voting-merkle-distribution-vault/DonationVotingMerkleDistributionVaultStrategy.sol:DonationVotingMerkleDistributionVaultStrategy contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                                                                                                         | Deployment Size |        |        |        |         |
| 3280719                                                                                                                                                                 | 17116           |        |        |        |         |
| Function Name                                                                                                                                                           | min             | avg    | median | max    | # calls |
| allocate                                                                                                                                                                | 5311            | 46446  | 44869  | 111864 | 13      |
| allocationEndTime                                                                                                                                                       | 404             | 1404   | 1404   | 2404   | 2       |
| allocationStartTime                                                                                                                                                     | 441             | 441    | 441    | 441    | 2       |
| allowedTokens                                                                                                                                                           | 2592            | 2592   | 2592   | 2592   | 1       |
| claim                                                                                                                                                                   | 22825           | 33152  | 26870  | 49762  | 3       |
| claims                                                                                                                                                                  | 787             | 787    | 787    | 787    | 2       |
| distribute                                                                                                                                                              | 7262            | 73177  | 98269  | 117494 | 8       |
| getAllo                                                                                                                                                                 | 271             | 271    | 271    | 271    | 56      |
| getPayouts                                                                                                                                                              | 19510           | 19510  | 19510  | 19510  | 1       |
| getPoolId                                                                                                                                                               | 371             | 406    | 371    | 2371   | 56      |
| getRecipient                                                                                                                                                            | 2559            | 2559   | 2559   | 2559   | 1       |
| getRecipientStatus                                                                                                                                                      | 1612            | 1612   | 1612   | 1612   | 2       |
| getStrategyId                                                                                                                                                           | 250             | 250    | 250    | 250    | 1       |
| hasBeenDistributed                                                                                                                                                      | 739             | 1739   | 1739   | 2739   | 2       |
| increasePoolAmount                                                                                                                                                      | 5507            | 20925  | 22607  | 22607  | 61      |
| initialize                                                                                                                                                              | 926             | 140457 | 145461 | 145461 | 57      |
| isDistributionSet                                                                                                                                                       | 395             | 1395   | 1395   | 2395   | 2       |
| isPoolActive                                                                                                                                                            | 627             | 1559   | 1559   | 2492   | 2       |
| isValidAllocator                                                                                                                                                        | 477             | 477    | 477    | 477    | 2       |
| metadataRequired                                                                                                                                                        | 388             | 388    | 388    | 388    | 1       |
| receive                                                                                                                                                                 | 55              | 55     | 55     | 55     | 65      |
| recipientsCounter                                                                                                                                                       | 352             | 352    | 352    | 352    | 23      |
| registerRecipient                                                                                                                                                       | 5309            | 129653 | 155605 | 155605 | 36      |
| registrationEndTime                                                                                                                                                     | 420             | 420    | 420    | 420    | 2       |
| registrationStartTime                                                                                                                                                   | 414             | 414    | 414    | 414    | 2       |
| reviewRecipients                                                                                                                                                        | 3109            | 14803  | 15437  | 15437  | 23      |
| statusesBitMap                                                                                                                                                          | 537             | 537    | 537    | 537    | 1       |
| updateDistribution                                                                                                                                                      | 3144            | 59610  | 73116  | 89616  | 12      |
| updatePoolTimestamps                                                                                                                                                    | 15246           | 18562  | 15383  | 25059  | 3       |
| useRegistryAnchor                                                                                                                                                       | 2378            | 2378   | 2378   | 2378   | 1       |
| withdraw                                                                                                                                                                | 15033           | 27773  | 22169  | 51721  | 4       |


| contracts/strategies/qv-simple/QVSimpleStrategy.sol:QVSimpleStrategy contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                               | Deployment Size |        |        |        |         |
| 2801455                                                                       | 14644           |        |        |        |         |
| Function Name                                                                 | min             | avg    | median | max    | # calls |
| addAllocator                                                                  | 4226            | 16006  | 7737   | 34137  | 112     |
| allocate                                                                      | 1982            | 72348  | 129542 | 129542 | 13      |
| allocationEndTime                                                             | 442             | 442    | 442    | 442    | 2       |
| allocationStartTime                                                           | 420             | 420    | 420    | 420    | 2       |
| distribute                                                                    | 12912           | 46870  | 51804  | 61484  | 6       |
| getAllo                                                                       | 271             | 271    | 271    | 271    | 54      |
| getPayouts                                                                    | 4611            | 13524  | 13524  | 22438  | 2       |
| getPoolId                                                                     | 327             | 364    | 327    | 2327   | 54      |
| getRecipient                                                                  | 3086            | 4086   | 4086   | 5086   | 2       |
| getRecipientStatus                                                            | 2428            | 4410   | 4428   | 12255  | 10      |
| getStrategyId                                                                 | 271             | 271    | 271    | 271    | 1       |
| increasePoolAmount                                                            | 591             | 19623  | 22795  | 22795  | 7       |
| initialize                                                                    | 891             | 113168 | 120853 | 120853 | 61      |
| isPoolActive                                                                  | 612             | 1547   | 1547   | 2483   | 2       |
| isValidAllocator                                                              | 2644            | 2644   | 2644   | 2644   | 3       |
| maxVoiceCreditsPerAllocator                                                   | 2352            | 2352   | 2352   | 2352   | 1       |
| metadataRequired                                                              | 2389            | 2389   | 2389   | 2389   | 1       |
| registerRecipient                                                             | 962             | 79418  | 103337 | 103337 | 30      |
| registrationEndTime                                                           | 413             | 413    | 413    | 413    | 2       |
| registrationStartTime                                                         | 381             | 1381   | 1381   | 2381   | 2       |
| removeAllocator                                                               | 14199           | 14583  | 14583  | 14968  | 2       |
| reviewRecipients                                                              | 3626            | 42075  | 32863  | 61048  | 50      |
| reviewsByStatus                                                               | 771             | 771    | 771    | 771    | 7       |
| updatePoolTimestamps                                                          | 15246           | 17821  | 15383  | 22835  | 3       |
| withdraw                                                                      | 17267           | 20313  | 20313  | 23360  | 2       |


| contracts/strategies/rfp-committee/RFPCommitteeStrategy.sol:RFPCommitteeStrategy contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                           | Deployment Size |        |        |        |         |
| 2616539                                                                                   | 13629           |        |        |        |         |
| Function Name                                                                             | min             | avg    | median | max    | # calls |
| allocate                                                                                  | 912             | 34742  | 49272  | 51992  | 8       |
| getAllo                                                                                   | 260             | 260    | 260    | 260    | 9       |
| getPoolId                                                                                 | 349             | 349    | 349    | 349    | 9       |
| getRecipientStatus                                                                        | 2758            | 2758   | 2758   | 2758   | 1       |
| getStrategyId                                                                             | 282             | 282    | 282    | 282    | 1       |
| initialize                                                                                | 1486            | 117720 | 140555 | 142555 | 12      |
| maxBid                                                                                    | 406             | 406    | 406    | 406    | 1       |
| metadataRequired                                                                          | 410             | 410    | 410    | 410    | 1       |
| registerRecipient                                                                         | 142103          | 164528 | 172003 | 172003 | 4       |
| setMilestones                                                                             | 104661          | 104661 | 104661 | 104661 | 3       |
| useRegistryAnchor                                                                         | 377             | 377    | 377    | 377    | 1       |
| voteThreshold                                                                             | 385             | 385    | 385    | 385    | 1       |
| votedFor                                                                                  | 629             | 629    | 629    | 629    | 2       |
| votes                                                                                     | 624             | 1290   | 624    | 2624   | 6       |


| contracts/strategies/rfp-simple/RFPSimpleStrategy.sol:RFPSimpleStrategy contract |                 |        |        |        |         |
|----------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                  | Deployment Size |        |        |        |         |
| 2556255                                                                          | 13322           |        |        |        |         |
| Function Name                                                                    | min             | avg    | median | max    | # calls |
| allocate                                                                         | 940             | 24607  | 26748  | 33834  | 22      |
| distribute                                                                       | 1359            | 37878  | 22598  | 69998  | 11      |
| getAllo                                                                          | 260             | 260    | 260    | 260    | 53      |
| getMilestone                                                                     | 2541            | 2541   | 2541   | 2541   | 5       |
| getMilestoneStatus                                                               | 754             | 754    | 754    | 754    | 2       |
| getPayouts                                                                       | 3683            | 3683   | 3683   | 3683   | 1       |
| getPoolId                                                                        | 371             | 371    | 371    | 371    | 53      |
| getRecipient                                                                     | 3295            | 4773   | 3295   | 13354  | 7       |
| getRecipientStatus                                                               | 2539            | 2615   | 2615   | 2691   | 2       |
| getStrategyId                                                                    | 304             | 304    | 304    | 304    | 1       |
| increaseMaxBid                                                                   | 14910           | 17658  | 17059  | 21006  | 3       |
| increasePoolAmount                                                               | 22629           | 22629  | 22629  | 22629  | 8       |
| initialize                                                                       | 1295            | 114038 | 117920 | 119920 | 58      |
| isPoolActive                                                                     | 393             | 393    | 393    | 393    | 1       |
| isValidAllocator                                                                 | 6578            | 10828  | 10828  | 15078  | 2       |
| maxBid                                                                           | 341             | 341    | 341    | 341    | 2       |
| metadataRequired                                                                 | 366             | 366    | 366    | 366    | 1       |
| receive                                                                          | 55              | 55     | 55     | 55     | 8       |
| registerRecipient                                                                | 1249            | 138885 | 171936 | 202378 | 33      |
| rejectMilestone                                                                  | 2819            | 6117   | 4998   | 14953  | 5       |
| setMilestones                                                                    | 3296            | 150429 | 175478 | 179978 | 22      |
| setPoolActive                                                                    | 8472            | 11172  | 12522  | 12522  | 3       |
| submitUpcomingMilestone                                                          | 799             | 23834  | 25187  | 32636  | 14      |
| useRegistryAnchor                                                                | 399             | 399    | 399    | 399    | 1       |
| withdraw                                                                         | 14962           | 22280  | 17108  | 34771  | 3       |



Ran 23 test suites: 831 tests passed, 0 failed, 0 skipped (831 total tests)

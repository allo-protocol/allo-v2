| contracts/core/Allo.sol:Allo contract |                 |        |        |        |         |
|---------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                       | Deployment Size |        |        |        |         |
| 2744384                               | 13739           |        |        |        |         |
| Function Name                         | min             | avg    | median | max    | # calls |
| addPoolManager                        | 1005            | 9220   | 2959   | 23698  | 3       |
| addToCloneableStrategies              | 2531            | 23048  | 23861  | 25861  | 45      |
| allocate                              | 5234            | 51333  | 40032  | 138575 | 57      |
| batchAllocate                         | 23652           | 48214  | 48214  | 72776  | 2       |
| batchRegisterRecipient                | 24157           | 49199  | 49199  | 74242  | 2       |
| createPool                            | 26687           | 464014 | 478535 | 478535 | 44      |
| createPoolWithCustomStrategy          | 2408            | 426972 | 412808 | 533384 | 755     |
| distribute                            | 14075           | 129160 | 92781  | 292987 | 13      |
| fundPool                              | 22548           | 94192  | 92121  | 121964 | 147     |
| getBaseFee                            | 394             | 394    | 394    | 394    | 2       |
| getFeeDenominator                     | 258             | 258    | 258    | 258    | 2       |
| getPercentFee                         | 404             | 1404   | 1404   | 2404   | 4       |
| getPool                               | 2921            | 6009   | 2921   | 16921  | 193     |
| getRegistry                           | 420             | 670    | 420    | 2420   | 758     |
| getStrategy                           | 550             | 550    | 550    | 550    | 42      |
| getTreasury                           | 399             | 399    | 399    | 399    | 2       |
| initialize                            | 2908            | 120847 | 120967 | 140867 | 818     |
| isCloneableStrategy                   | 677             | 1177   | 677    | 2677   | 4       |
| isPoolAdmin                           | 950             | 1950   | 1950   | 2950   | 2       |
| isPoolManager                         | 999             | 5049   | 3488   | 9488   | 981     |
| recoverFunds                          | 2610            | 19544  | 21399  | 34625  | 3       |
| registerRecipient                     | 6058            | 129129 | 157072 | 205379 | 74      |
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
| createProfile                                 | 2627            | 699940              | 700009 | 830027              | 2486    |
| getProfileByAnchor                            | 3585            | 15374               | 19585  | 20071               | 274     |
| getProfileById                                | 3776            | 3781                | 3776   | 5240                | 2466    |
| hasRole                                       | 743             | 743                 | 743    | 743                 | 1       |
| initialize                                    | 22848           | 48614               | 48645  | 48645               | 856     |
| isMemberOfProfile                             | 816             | 1649                | 816    | 2816                | 12      |
| isOwnerOfProfile                              | 713             | 713                 | 713    | 713                 | 7       |
| isOwnerOrMemberOfProfile                      | 0               | 992                 | 696    | 5016                | 1043    |
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



Ran 25 test suites: 878 tests passed, 0 failed, 0 skipped (878 total tests)

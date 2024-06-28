| contracts/core/Allo.sol:Allo contract |                 |        |        |        |         |
|---------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                       | Deployment Size |        |        |        |         |
| 2900525                               | 13253           |        |        |        |         |
| Function Name                         | min             | avg    | median | max    | # calls |
| addPoolManager                        | 26337           | 35379  | 26531  | 53270  | 3       |
| allocate                              | 38534           | 87818  | 75130  | 187732 | 78      |
| batchAllocate                         | 46001           | 77297  | 77297  | 108593 | 2       |
| batchRegisterRecipient                | 46573           | 78349  | 78349  | 110126 | 2       |
| createPool                            | 49070           | 526861 | 541827 | 541827 | 51      |
| createPoolWithCustomStrategy          | 26904           | 483195 | 463419 | 573359 | 910     |
| distribute                            | 65408           | 135067 | 167627 | 167627 | 9       |
| fundPool                              | 43880           | 132358 | 136025 | 162056 | 171     |
| getBaseFee                            | 372             | 372    | 372    | 372    | 2       |
| getPercentFee                         | 382             | 382    | 382    | 382    | 2       |
| getPool                               | 2944            | 10582  | 12944  | 16944  | 216     |
| getRegistry                           | 420             | 1005   | 420    | 2420   | 1237    |
| getStrategy                           | 572             | 572    | 572    | 572    | 42      |
| getTreasury                           | 399             | 399    | 399    | 399    | 2       |
| initialize                            | 25552           | 143430 | 143531 | 163503 | 975     |
| isPoolAdmin                           | 972             | 1972   | 1972   | 2972   | 2       |
| isPoolManager                         | 999             | 7657   | 9488   | 9488   | 1345    |
| recoverFunds                          | 24158           | 45301  | 52832  | 58913  | 3       |
| registerRecipient                     | 54289           | 161046 | 183137 | 203037 | 48      |
| removePoolManager                     | 26574           | 28944  | 28944  | 31315  | 2       |
| transferOwnership                     | 28567           | 28567  | 28567  | 28567  | 45      |
| updateBaseFee                         | 23708           | 41126  | 46933  | 46933  | 4       |
| updatePercentFee                      | 23670           | 24995  | 24985  | 29857  | 234     |
| updatePoolMetadata                    | 32065           | 37348  | 37348  | 42632  | 2       |
| updateRegistry                        | 23800           | 25954  | 23942  | 30121  | 3       |
| updateTreasury                        | 23821           | 25979  | 23963  | 30153  | 3       |


| contracts/core/Registry.sol:Registry contract |                 |                     |         |                     |         |
|-----------------------------------------------|-----------------|---------------------|---------|---------------------|---------|
| Deployment Cost                               | Deployment Size |                     |         |                     |         |
| 2591146                                       | 11856           |                     |         |                     |         |
| Function Name                                 | min             | avg                 | median  | max                 | # calls |
| ALLO_OWNER                                    | 240             | 240                 | 240     | 240                 | 1       |
| addMembers                                    | 25550           | 49621               | 50337   | 75598               | 67      |
| addOwners                                     | 25097           | 2944749             | 2819266 | 6503056             | 514     |
| anchorToProfileId                             | 609             | 609                 | 609     | 609                 | 258     |
| createProfile                                 | 29386           | 940326              | 727741  | 7224711             | 3721    |
| getProfileByAnchor                            | 3894            | 12317               | 17407   | 35358               | 623     |
| getProfileById                                | 3576            | 3580                | 3576    | 5040                | 3191    |
| hasRole                                       | 742             | 742                 | 742     | 742                 | 1       |
| initialize                                    | 44040           | 70051               | 70077   | 70077               | 1011    |
| isMemberOfProfile                             | 816             | 835                 | 816     | 2816                | 524     |
| isOwnerOfProfile                              | 967             | 967                 | 967     | 2967                | 89786   |
| isOwnerOrMemberOfProfile                      | 0               | 3171                | 2983    | 5303                | 1329    |
| recoverFunds                                  | 24236           | 40887               | 40082   | 59149               | 4       |
| removeMembers                                 | 26126           | 29036               | 28558   | 32902               | 4       |
| removeOwners                                  | 25140           | 769139              | 712856  | 1687152             | 257     |
| updateProfileMetadata                         | 25913           | 29441               | 25925   | 36487               | 3       |
| updateProfileName                             | 25354           | 2553540988718944009 | 545717  | 8937393460515966468 | 7       |


| contracts/factories/ContractFactory.sol:ContractFactory contract |                 |        |        |        |         |
|------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                  | Deployment Size |        |        |        |         |
| 381784                                                           | 1483            |        |        |        |         |
| Function Name                                                    | min             | avg    | median | max    | # calls |
| deploy                                                           | 67906           | 353819 | 354501 | 638368 | 4       |
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
| initialize                                                                                            | 30284           | 89872  | 115237 | 120628 | 5       |
| isPoolActive                                                                                          | 671             | 1670   | 1670   | 2670   | 2       |
| isValidAllocator                                                                                      | 667             | 1667   | 1667   | 2667   | 12      |
| maxVoiceCreditsPerAllocator                                                                           | 2396            | 2396   | 2396   | 2396   | 2       |
| payouts                                                                                               | 613             | 613    | 613    | 613    | 2       |
| recoverFunds                                                                                          | 36711           | 54747  | 60822  | 66708  | 3       |
| removeAllocator                                                                                       | 33432           | 34802  | 34802  | 36172  | 2       |
| setPayouts                                                                                            | 35989           | 105941 | 137944 | 140971 | 11      |
| updatePoolTimestamps                                                                                  | 32050           | 35749  | 36436  | 38763  | 3       |


| contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol:DonationVotingMerkleDistributionDirectTransferStrategy contract |                 |        |        |        |         |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                                                                                                                                     | Deployment Size |        |        |        |         |
| 3793306                                                                                                                                                                                             | 18151           |        |        |        |         |
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
| registerRecipient                                                                                                                                                                                   | 28572           | 157158 | 179050 | 179050 | 33      |
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
| 3572645                                                                                                                                                                 | 17126           |        |        |        |         |
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
| registerRecipient                                                                                                                                                       | 28541           | 158930 | 178997 | 178997 | 36      |
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
| 3080335                                                                       | 14665           |        |        |        |         |
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
| initialize                                                                    | 23532           | 124344 | 125582 | 125582 | 263     |
| isPoolActive                                                                  | 634             | 1569   | 1569   | 2505   | 2       |
| isValidAllocator                                                              | 2667            | 2667   | 2667   | 2667   | 3       |
| maxVoiceCreditsPerAllocator                                                   | 2396            | 2396   | 2396   | 2396   | 1       |
| metadataRequired                                                              | 2389            | 2389   | 2389   | 2389   | 1       |
| registerRecipient                                                             | 23932           | 119621 | 148448 | 148448 | 30      |
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
| 2864915                                                                                   | 13592           |        |        |        |         |
| Function Name                                                                             | min             | avg    | median | max    | # calls |
| allocate                                                                                  | 22980           | 72231  | 86060  | 94963  | 8       |
| getAllo                                                                                   | 260             | 260    | 260    | 260    | 9       |
| getPoolId                                                                                 | 349             | 349    | 349    | 349    | 9       |
| getRecipientStatus                                                                        | 2758            | 2758   | 2758   | 2758   | 1       |
| getStrategyId                                                                             | 282             | 282    | 282    | 282    | 1       |
| initialize                                                                                | 23590           | 94655  | 95186  | 164659 | 4       |
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
| 2800427                                                                          | 13285           |        |        |        |         |
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
| initialize                                                                       | 23259           | 102698 | 141884 | 141896 | 6       |
| isPoolActive                                                                     | 393             | 393    | 393    | 393    | 1       |
| isValidAllocator                                                                 | 6578            | 10828  | 10828  | 15078  | 2       |
| maxBid                                                                           | 341             | 341    | 341    | 341    | 2       |
| metadataRequired                                                                 | 366             | 366    | 366    | 366    | 1       |
| registerRecipient                                                                | 28429           | 163365 | 195116 | 225758 | 33      |
| rejectMilestone                                                                  | 36145           | 41629  | 40511  | 45490  | 5       |
| setMilestones                                                                    | 36643           | 178228 | 203838 | 203838 | 22      |
| setPoolActive                                                                    | 36164           | 37038  | 37475  | 37475  | 3       |
| submitUpcomingMilestone                                                          | 28647           | 54907  | 57135  | 57135  | 14      |
| useRegistryAnchor                                                                | 399             | 399    | 399    | 399    | 1       |
| withdraw                                                                         | 36394           | 48545  | 38540  | 70703  | 3       |




Ran 29 test suites in 5.81s (6.66s CPU time): 1034 tests passed, 0 failed, 0 skipped (1034 total tests)

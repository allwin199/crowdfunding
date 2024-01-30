# CrowdFunding

## About

This application allows users to create fundraising campaigns, and other participants can contribute funds to support these campaigns. Once a campaign reaches its deadline, the creator, can withdraw the accumulated funds.

## Workflow

![Tree Image](./tree_example.png)

-   [Checkout the complete worflow](./test/CrowdFunding.tree)

## Test

```
forge test
```

or

```
forge test --rpc-url <RPC_URL>
```

| File                               | % Lines        | % Statements   | % Branches     | % Funcs         |
| ---------------------------------- | -------------- | -------------- | -------------- | --------------- |
| script/DeployCrowdFunding.s.sol    | 100.00% (4/4)  | 100.00% (5/5)  | 100.00% (0/0)  | 100.00% (1/1)   |
| src/CrowdFunding.sol               | 93.10% (54/58) | 93.75% (60/64) | 92.31% (24/26) | 100.00% (9/9)   |
| test/mocks/MocksWithdrawFailed.sol | 100.00% (1/1)  | 100.00% (1/1)  | 100.00% (0/0)  | 100.00% (1/1)   |
| Total                              | 93.65% (59/63) | 94.29% (66/70) | 92.31% (24/26) | 100.00% (11/11) |

## Deployment

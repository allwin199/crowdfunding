# CrowdFunding

## About

This application allows users to create fundraising campaigns, and other participants can contribute funds to support these campaigns. Once a campaign reaches its deadline, the creator can withdraw the accumulated funds.

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

| File                               | % Lines         | % Statements    | % Branches      | % Funcs         |
| ---------------------------------- | --------------- | --------------- | --------------- | --------------- |
| script/DeployCrowdFunding.s.sol    | 100.00% (4/4)   | 100.00% (5/5)   | 100.00% (0/0)   | 100.00% (1/1)   |
| src/CrowdFunding.sol               | 100.00% (58/58) | 100.00% (64/64) | 100.00% (26/26) | 100.00% (9/9)   |
| test/mocks/MocksWithdrawFailed.sol | 100.00% (1/1)   | 100.00% (1/1)   | 100.00% (0/0)   | 100.00% (1/1)   |
| Total                              | 100.00% (63/63) | 100.00% (70/70) | 100.00% (26/26) | 100.00% (11/11) |

## Deployment

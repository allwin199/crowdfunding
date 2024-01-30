// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployCrowdFunding} from "../../script/DeployCrowdFunding.s.sol";
import {CrowdFunding} from "../../src/CrowdFunding.sol";

contract DeployCrowdFundingTest is Test {
    CrowdFunding crowdFunding;

    function setUp() external {
        DeployCrowdFunding deployer = new DeployCrowdFunding();
        crowdFunding = deployer.run();
    }

    function test_DeployCrowfunding_IsNotZeroAddress() public view {
        assert(address(crowdFunding) != address(0));
    }
}

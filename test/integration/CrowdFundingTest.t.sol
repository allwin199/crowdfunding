// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployCrowdFunding} from "../../script/DeployCrowdFunding.s.sol";
import {CrowdFunding} from "../../src/CrowdFunding.sol";
import {MocksWithdrawFailed} from "../mocks/MocksWithdrawFailed.sol";

contract CrowdFundingTest is Test {
    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////

    DeployCrowdFunding private deployer;
    CrowdFunding private crowdFunding;

    address private user = makeAddr("user");
    address private funder = makeAddr("funder");
    uint256 private constant STARTING_BALANCE = 100e18;

    //campaign details
    string private constant CAMPAIGN_NAME = "campaign1";
    string private constant CAMPAIGN_DESCRIPTION = "campaign1 description";
    uint256 private constant TARGET_AMOUNT = 10e18;
    uint256 private constant FUNDING_AMOUNT = 1e18;
    uint256 private startAt = block.timestamp;
    uint256 private constant THIRTY_DAYS = 2592000; // 30 * 86400
    uint256 private endAt = block.timestamp + THIRTY_DAYS - 100;
    string private constant IMAGE =
        "https://www.mygoldenretrieverpuppies.com/wp-content/uploads/2022/06/Golden-Retriever-Puppies.jpeg";

    //////////////////////////////////////////////////////////
    //////////////////////   Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 indexed targetAmount,
        uint256 startAt,
        uint256 endAt
    );
    event CamapignFunded(uint256 indexed campaignId, address indexed funder, uint256 indexed amount);
    event WithdrawSuccessful(uint256 indexed campaignId, address indexed owner, uint256 indexed amount);

    function setUp() external {
        deployer = new DeployCrowdFunding();
        crowdFunding = deployer.run();

        // let's give funds to the user
        vm.deal(user, STARTING_BALANCE);
        vm.deal(funder, STARTING_BALANCE);
    }

    //////////////////////////////////////////////////////////
    ///////////////  Create Campaign Tests  //////////////////
    //////////////////////////////////////////////////////////

    function test_TotalCampaigns_IsZero() public {
        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();
        assertEq(totalCampaigns, 0);
    }

    // function test_RevertsIf_CreateCampaign_StartDateIs_NotInPresent() public {
    //     vm.startPrank(user);
    //     vm.warp(block.timestamp + 100);
    //     vm.roll(block.number + 1);
    //     vm.expectRevert(CrowdFunding.CrowdFunding__StartDate_ShouldBeInPresent.selector);
    //     crowdFunding.createCampaign(
    //         CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, (block.timestamp) - 50, endAt, IMAGE
    //     );
    //     vm.stopPrank();
    // }

    function test_RevertsIf_CreateCampaign_EndDateLessThan_StartDate() public {
        vm.startPrank(user);
        vm.warp(block.timestamp + 100);
        vm.roll(block.number + 1);
        vm.expectRevert(CrowdFunding.CrowdFunding__InvalidTimeline.selector);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, (block.timestamp) - 50, IMAGE);
        vm.stopPrank();
    }

    // function test_RevertsIf_CreateCampaign_EndDateMoreThan_30days() public {
    //     vm.startPrank(user);
    //     vm.expectRevert(CrowdFunding.CrowdFunding_MaxTimeIs_30days.selector);
    //     crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, startAt, endAt + 101, IMAGE);
    //     vm.stopPrank();
    // }

    function test_UserCan_CreateCampaign_ReturnsCamapignId() public {
        vm.startPrank(user);
        uint256 campaignId =
            crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);
        vm.stopPrank();

        assertEq(campaignId, 1);
    }

    function test_UserCan_CreateCampaign_UpdatesCampaignsArray() public {
        vm.startPrank(user);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);
        vm.stopPrank();

        CrowdFunding.Campaign[] memory campaigns = crowdFunding.getCampaigns();
        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();

        assertEq(campaigns.length, totalCampaigns);
    }

    function test_UserCan_CreateCampaign_UpdatesMapping() public {
        vm.startPrank(user);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);
        vm.stopPrank();

        CrowdFunding.Campaign memory currentCampaign = crowdFunding.getCampaign(0);

        assertEq(currentCampaign.name, CAMPAIGN_NAME);
    }

    function test_UserCan_CreateCampaign_UpdatesCreatorMapping() public {
        vm.startPrank(user);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);

        CrowdFunding.Campaign[] memory campaignCreatedByUser = crowdFunding.getCampaignsCreatedByUser();

        vm.stopPrank();
        uint256 currentCampaignId = campaignCreatedByUser[0].id;

        assertEq(currentCampaignId, 0);
    }

    function test_UserCan_CreateMultipleCampaigns_UpdatesCreatorMapping() public {
        vm.startPrank(user);

        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);

        crowdFunding.createCampaign("campaign 2", CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);

        crowdFunding.createCampaign("campaign 3", CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);

        CrowdFunding.Campaign[] memory campaignCreatedByUser = crowdFunding.getCampaignsCreatedByUser();

        vm.stopPrank();
        uint256 currentCampaignId = campaignCreatedByUser[1].id;

        assertEq(currentCampaignId, 1);
    }

    function test_UserCan_CreateCampaign_EmitsEvent() public {
        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();
        vm.startPrank(user);
        vm.expectEmit(true, true, true, false, address(crowdFunding)); // crowFunding contract will emit this event
        emit CampaignCreated(totalCampaigns, user, TARGET_AMOUNT, startAt, endAt);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);
        vm.stopPrank();
    }

    modifier CampaignCreatedByUser() {
        vm.startPrank(user);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);
        vm.stopPrank();
        _;
    }

    function test_CampaignCount_IncreasesAfter_CamapignCreation() public CampaignCreatedByUser {
        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();
        assertEq(totalCampaigns, 1);
    }

    //////////////////////////////////////////////////////////
    ///////////////  Funding Campaign Tests  /////////////////
    //////////////////////////////////////////////////////////

    function test_RevertsIf_FundingAmount_IsZero() public CampaignCreatedByUser {
        vm.startPrank(funder);
        vm.expectRevert(CrowdFunding.CrowdFunding__FundingWith_ZeroAmount.selector);
        crowdFunding.fundCampaign(1);
        vm.stopPrank();
    }

    function test_RevertsIf_FundingAn_InvalidCampaign() public {
        vm.startPrank(funder);
        vm.expectRevert();
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(10);
        vm.stopPrank();
    }

    function test_FunderCan_FundCampaign() public CampaignCreatedByUser {
        uint256 totalCampaigns = crowdFunding.getTotalCampaigns();
        console.log("totalCampaigns", totalCampaigns);
        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        address[] memory fundersList = crowdFunding.getFunders(0);
        assertEq(fundersList[0], funder);
    }

    function test_FunderCan_FundCampaignAnd_UpdatesBalance() public CampaignCreatedByUser {
        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        uint256 totalAmountInCampaign = crowdFunding.getCampaign(0).amountCollected;
        assertEq(totalAmountInCampaign, FUNDING_AMOUNT);
    }

    function test_FunderCan_FundCampaignAnd_UpdatesFundersMapping() public CampaignCreatedByUser {
        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        uint256 funderFunded = crowdFunding.getFunderInfo(0, funder);
        assertEq(funderFunded, FUNDING_AMOUNT);
    }

    function test_FunderCan_FundCampaignAnd_UpdatesFundersArray() public CampaignCreatedByUser {
        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        address[] memory funders = crowdFunding.getFunders(0);
        assertEq(funders[0], funder);
    }

    function test_FunderCan_FundCampaignAnd_UpdatesFundersLength() public CampaignCreatedByUser {
        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        address[] memory funders = crowdFunding.getFunders(0);
        assertEq(funders.length, 1);
    }

    function test_FundersLength_ShouldNotChange_ForOldFunder() public CampaignCreatedByUser {
        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        address[] memory funders = crowdFunding.getFunders(0);
        assertEq(funders.length, 1);
    }

    function test_FundersLength_ShouldChange_ForNewFunder() public CampaignCreatedByUser {
        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        address newFunder = makeAddr("newFunder");
        vm.deal(newFunder, STARTING_BALANCE);
        vm.startPrank(newFunder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        address[] memory funders = crowdFunding.getFunders(0);
        assertEq(funders.length, 2);
    }

    function test_FunderCan_FundCampaign_EmitsEvent() public CampaignCreatedByUser {
        vm.startPrank(funder);

        vm.expectEmit(true, true, true, false, address(crowdFunding));
        emit CamapignFunded(0, funder, FUNDING_AMOUNT);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);

        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    ////////////////////  Withdraw Tests  ////////////////////
    //////////////////////////////////////////////////////////

    modifier CampaignCreatedAndFunded() {
        vm.startPrank(user);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);
        vm.stopPrank();

        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        _;
    }

    function test_RevertsIf_WithdrawNotCalled_ByOwner() public CampaignCreatedAndFunded {
        vm.startPrank(funder);
        vm.expectRevert(CrowdFunding.CrowdFunding__OnlyOwner_CanWithdraw.selector);
        crowdFunding.withdraw(0);
        vm.stopPrank();
    }

    function test_RevertsIf_WithdrawCalled_BeforeEndDate() public CampaignCreatedAndFunded {
        vm.startPrank(user);
        vm.expectRevert(CrowdFunding.CrowdFunding__CampaignNotEnded.selector);
        crowdFunding.withdraw(0);
        vm.stopPrank();
    }

    function test_RevertsIf_WithdrawCalled_ButBalanceZero() public CampaignCreatedByUser {
        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        vm.expectRevert(CrowdFunding.CrowdFunding__BalanceIsZero.selector);
        crowdFunding.withdraw(0);
        vm.stopPrank();
    }

    function test_OwnerCan_Withdraw() public CampaignCreatedAndFunded {
        vm.warp(block.timestamp + THIRTY_DAYS + 100);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        crowdFunding.withdraw(0);
        vm.stopPrank();
    }

    function test_OwnerCanWithdraw_UpdatesOwnerBalance() public CampaignCreatedAndFunded {
        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        vm.roll(block.number + 1);

        uint256 startingOwnerBalance = address(user).balance;
        uint256 campaignBalance = crowdFunding.getCampaign(0).amountCollected;

        vm.startPrank(user);
        crowdFunding.withdraw(0);
        vm.stopPrank();

        uint256 endingOwnerBalance = address(user).balance;

        assertEq(endingOwnerBalance, startingOwnerBalance + campaignBalance);
    }

    function test_OwnerCanWithdraw_UpdatesCampaignBalance() public CampaignCreatedAndFunded {
        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        crowdFunding.withdraw(0);
        vm.stopPrank();

        uint256 campaignBalance = crowdFunding.getCampaign(0).amountCollected;

        assertEq(campaignBalance, 0);
    }

    function test_OwnerAlready_Withdrawn() public CampaignCreatedAndFunded {
        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        crowdFunding.withdraw(0);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(CrowdFunding.CrowdFunding__AmountAlready_WithdrawnByOwner.selector);
        crowdFunding.withdraw(0);
        vm.stopPrank();
    }

    function test_OwnerCan_Withdraw_EmitsEvent() public CampaignCreatedAndFunded {
        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        vm.roll(block.number + 1);

        uint256 campaignBalance = crowdFunding.getCampaign(0).amountCollected;

        vm.startPrank(user);
        vm.expectEmit(true, true, true, false, address(crowdFunding));
        emit WithdrawSuccessful(0, user, campaignBalance);
        crowdFunding.withdraw(0);
        vm.stopPrank();
    }

    function test_WithdrawFailed() public {
        MocksWithdrawFailed mocksWithdrawFailed = new MocksWithdrawFailed();
        address mockUser = address(mocksWithdrawFailed);

        vm.startPrank(mockUser);
        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);
        vm.stopPrank();

        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();

        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        vm.roll(block.number + 1);

        vm.startPrank(mockUser);
        vm.expectRevert(CrowdFunding.CrowdFunding__WithdrawFailed.selector);
        crowdFunding.withdraw(0);
        vm.stopPrank();
    }

    function test_RevertsIf_CampaignAlreadyEnded() public CampaignCreatedAndFunded {
        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        crowdFunding.withdraw(0);
        vm.stopPrank();

        vm.startPrank(funder);
        vm.expectRevert(CrowdFunding.CrowdFunding__CampaignAlreadyEnded.selector);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        vm.stopPrank();
    }

    function test_OwnerCanWithdraw_AfterMultipleFunding() public CampaignCreatedAndFunded {
        for (uint160 i = 1; i < 5; i++) {
            address newfunder = address(i);
            hoax(newfunder, STARTING_BALANCE);
            crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(0);
        }

        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        vm.roll(block.number + 1);

        uint256 startingOwnerBalance = address(user).balance;
        uint256 campaignBalance = crowdFunding.getCampaign(0).amountCollected;

        vm.startPrank(user);
        crowdFunding.withdraw(0);
        vm.stopPrank();

        uint256 endingOwnerBalance = address(user).balance;

        assertEq(endingOwnerBalance, startingOwnerBalance + campaignBalance);
    }

    function test_UserCanCreate_MultipleCampaigns() public {
        vm.startPrank(user);

        crowdFunding.createCampaign(CAMPAIGN_NAME, CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);

        crowdFunding.createCampaign("campaign 2", CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);

        crowdFunding.createCampaign("campaign 3", CAMPAIGN_DESCRIPTION, TARGET_AMOUNT, endAt, IMAGE);

        vm.stopPrank();

        vm.startPrank(funder);
        crowdFunding.fundCampaign{value: (FUNDING_AMOUNT / 2)}(0);
        crowdFunding.fundCampaign{value: FUNDING_AMOUNT}(1);
        vm.stopPrank();

        vm.warp(block.timestamp + THIRTY_DAYS + 1);
        vm.roll(block.number + 1);

        uint256 startingOwnerBalance = address(user).balance;
        uint256 campaign1Balance = crowdFunding.getCampaign(0).amountCollected;
        uint256 campaign2Balance = crowdFunding.getCampaign(1).amountCollected;

        vm.startPrank(user);
        crowdFunding.withdraw(1);
        vm.stopPrank();

        uint256 endingOwnerBalance = address(user).balance;

        assertEq(endingOwnerBalance, startingOwnerBalance + campaign2Balance, "ownerBalance");
        assertEq(campaign1Balance, (FUNDING_AMOUNT / 2), "campaign1Balance");
    }
}

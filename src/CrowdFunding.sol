// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Crowfunding Contract
/// @author Prince Allwin
/// @notice User can create a campaign and funders can fund the campaign
contract CrowdFunding {
    //////////////////////////////////////////////////////////
    ////////////////////  Custom Errors  /////////////////////
    //////////////////////////////////////////////////////////
    error CrowdFunding__StartDate_ShouldBeInPresent();
    error CrowdFunding__InvalidTimeline();
    error CrowdFunding__OnlyOwner_CanWithdraw();
    error CrowdFunding__CampaignNotEnded();
    error CrowdFunding__WithdrawFailed();
    error CrowdFunding__FundingWith_ZeroAmount();
    error CrowdFunding__InvalidCampaign();
    error CrowdFunding_MaxTimeIs_30days();
    error CrowdFunding__BalanceIsZero();
    error CrowdFunding__AmountAlready_WithdrawnByOwner();
    error CrowdFunding__CampaignAlreadyEnded();

    //////////////////////////////////////////////////////////
    ////////////////  Type Declarations  /////////////////////
    //////////////////////////////////////////////////////////
    struct Campaign {
        address payable creator;
        uint256 id;
        string name;
        string description;
        uint256 targetAmount;
        uint256 amountCollected;
        uint256 startAt;
        uint256 endAt;
        string image;
        address[] funders;
        bool claimedByOwner;
    }

    //////////////////////////////////////////////////////////
    ///////////  Constant and Immutable Variables  ///////////
    //////////////////////////////////////////////////////////
    uint256 private constant THIRTY_DAYS = 2592000; // 30 * 86400

    //////////////////////////////////////////////////////////
    ////////////////  Storage Variables  /////////////////////
    //////////////////////////////////////////////////////////
    uint256 private s_campaignsCount = 1;
    mapping(uint256 campaignId => Campaign) private s_campaigns;
    mapping(address creator => Campaign[] campaigns) private s_campaignCreatedByCreator;
    mapping(uint256 campaignId => mapping(address funders => uint256 amount)) s_addressToAmountFundedByCampaign;

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

    //////////////////////////////////////////////////////////
    //////////////////////  Functions  ///////////////////////
    //////////////////////////////////////////////////////////
    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _targetAmount,
        uint256 _startAt,
        uint256 _endAt,
        string memory _image
    ) external returns (uint256) {
        if (_startAt < block.timestamp) {
            revert CrowdFunding__StartDate_ShouldBeInPresent();
        }
        if (_endAt < _startAt) {
            revert CrowdFunding__InvalidTimeline();
        }
        if (_endAt > THIRTY_DAYS) {
            revert CrowdFunding_MaxTimeIs_30days();
        }

        Campaign memory newCampaign = Campaign({
            creator: payable(msg.sender),
            id: s_campaignsCount,
            name: _name,
            description: _description,
            targetAmount: _targetAmount,
            amountCollected: 0,
            startAt: _startAt,
            endAt: _endAt,
            image: _image,
            funders: new address[](0),
            claimedByOwner: false
        });

        s_campaigns[s_campaignsCount] = newCampaign;

        emit CampaignCreated(s_campaignsCount, msg.sender, _targetAmount, _startAt, _endAt);

        s_campaignCreatedByCreator[msg.sender].push(newCampaign);

        s_campaignsCount = s_campaignsCount + 1;

        return s_campaignsCount - 1;
    }

    function fundCampaign(uint256 campaignId) external payable {
        if (msg.value == 0) {
            revert CrowdFunding__FundingWith_ZeroAmount();
        }

        if (s_campaigns[campaignId].creator == address(0)) {
            revert CrowdFunding__InvalidCampaign();
        }

        if (s_campaigns[campaignId].claimedByOwner) {
            revert CrowdFunding__CampaignAlreadyEnded();
        }

        uint8 newFunder = 1;

        address[] memory funders = s_campaigns[campaignId].funders;

        for (uint256 i = 0; i < funders.length;) {
            if (funders[i] == msg.sender) {
                newFunder = 2;
                break;
            }

            unchecked {
                ++i;
            }
        }

        if (newFunder == 1) {
            s_campaigns[campaignId].funders.push(msg.sender);
        }

        s_campaigns[campaignId].amountCollected = s_campaigns[campaignId].amountCollected + msg.value;

        s_addressToAmountFundedByCampaign[campaignId][msg.sender] =
            s_addressToAmountFundedByCampaign[campaignId][msg.sender] + msg.value;

        emit CamapignFunded(campaignId, msg.sender, msg.value);
    }

    function withdraw(uint256 campaignId) external {
        address creator = s_campaigns[campaignId].creator;
        if (creator != msg.sender) {
            revert CrowdFunding__OnlyOwner_CanWithdraw();
        }

        if (s_campaigns[campaignId].endAt > block.timestamp) {
            revert CrowdFunding__CampaignNotEnded();
        }

        if (s_campaigns[campaignId].claimedByOwner) {
            revert CrowdFunding__AmountAlready_WithdrawnByOwner();
        }

        if (s_campaigns[campaignId].amountCollected == 0) {
            revert CrowdFunding__BalanceIsZero();
        }

        s_campaigns[campaignId].claimedByOwner = true;

        uint256 totalAmount = s_campaigns[campaignId].amountCollected;

        s_campaigns[campaignId].amountCollected = 0;

        emit WithdrawSuccessful(campaignId, msg.sender, totalAmount);

        (bool success,) = creator.call{value: totalAmount}("");
        if (!success) {
            revert CrowdFunding__WithdrawFailed();
        }
    }

    //////////////////////////////////////////////////////////
    //////////////////  Getter Functions  ////////////////////
    //////////////////////////////////////////////////////////
    function getTotalCampaigns() external view returns (uint256) {
        return s_campaignsCount - 1;
        // since s_campaignsCount starting from 1
        // to get the actual campaignCount we have to subtract by 1
    }

    function getCampaigns() external view returns (Campaign[] memory) {
        uint256 totalCampaigns = (s_campaignsCount - 1);
        Campaign[] memory allCampaigns = new Campaign[](totalCampaigns);

        for (uint256 i = 0; i < totalCampaigns;) {
            allCampaigns[i] = s_campaigns[i];

            unchecked {
                ++i;
            }
        }

        return allCampaigns;
    }

    function getCampaign(uint256 campaignId) external view returns (Campaign memory) {
        return s_campaigns[campaignId];
    }

    function getFunders(uint256 campaignId) external view returns (address[] memory) {
        address[] memory funders = s_campaigns[campaignId].funders;
        return funders;
    }

    function getFunderInfo(uint256 campaignId, address funder) external view returns (uint256) {
        return s_addressToAmountFundedByCampaign[campaignId][funder];
    }

    function getCampaignsCreatedByUser() external view returns (Campaign[] memory) {
        return s_campaignCreatedByCreator[msg.sender];
    }
}

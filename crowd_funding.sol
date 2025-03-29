// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract CrowdFunding {
    string public name; // name of the campaign
    string public description; // description for the campaign
    uint256 public goal; // target amount
    uint256 public deadline; // timestamp format
    address public creator; // campaign creator
    uint256 public totalCommittedFunds;
    uint256 public totalFlexibleFunds;
    uint256 public flexibleFundBalance; // should track the balance in the contract

    struct backerInfo {
        uint256 flexibleFund;
        uint256 committedFund;
    }

    mapping(address => backerInfo) public backers;

    enum Status {
        OPEN, 
        SUCCESS, 
        FAIL
    }

    Status public campaignStatus;

    modifier onlyCreator() {
        require(msg.sender == creator, "Not the creator");
        _;
    }

    modifier campaignDeadlineCheck() {
        require(block.timestamp < deadline, "campagin deadline expired");
        _;
    }

    constructor(
        address _creator, 
        uint256 _goal, 
        uint256 _deadline,
        string memory _name,
        string memory _description
    ) {
        require(_creator != address(0), "creator shouldn't be invalid address");
        require(_goal >= 1, "Goal must larger than or equal to 1");
        require(_deadline > block.timestamp, "Deadline must be greater than current timestamp");
        require(bytes(_name).length > 0, "Not allow Empty Name");
        require(bytes(_description).length > 0, "Not allow Empty Description");

        creator = _creator;
        goal = _goal;
        deadline = _deadline;
        name = _name;
        description = _description;
        campaignStatus = Status.OPEN;
    }

    function update_campaign_status() public {
        uint256 totalFunds = totalCommittedFunds + totalFlexibleFunds;

        if (totalFunds >= goal) campaignStatus = Status.SUCCESS;
        if (block.timestamp >= deadline && totalFunds < goal) campaignStatus = Status.FAIL;
    }
   
    function fund(bool isFlexible) campaignDeadlineCheck public payable {
        require(msg.value > 0, "Fund amount must larger than 0");
        if(campaignStatus == Status.SUCCESS) require(isFlexible == false, "can't not make flexible fund when the campaign is success");
        if (!isFlexible) {
            totalCommittedFunds += msg.value;
            backers[msg.sender].committedFund += msg.value;

            (bool success,) = creator.call{value: msg.value}("");
            require(success, "Transcation failed");
        }
        else{
            totalFlexibleFunds += msg.value;
            flexibleFundBalance += msg.value;
            backers[msg.sender].flexibleFund += msg.value;
        }

        update_campaign_status();
    }

    function refund_flexiable_funds(uint256 amount) public {
        update_campaign_status();
        
        // able to refund when not expired or expired and fail (meaning if the status is not success can refund anytime)
        require(campaignStatus != Status.SUCCESS, 
        "only able to refund status is not equal success");


        uint256 balance = backers[msg.sender].flexibleFund;
        require(balance >= amount, "Must have fund larager than refunded amount");
        
        totalFlexibleFunds -= amount;
        flexibleFundBalance -= amount;
        
        backers[msg.sender].flexibleFund -= amount;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transaction failed");
    }

    function withdraw_remaining_funds() public onlyCreator {
        update_campaign_status();
        require(campaignStatus == Status.SUCCESS, "the campagin is not success yet");
        
        uint256 temp = flexibleFundBalance;
        flexibleFundBalance = 0;

        (bool success,) = payable(creator).call{value: temp}("");
        require(success, "Transaction failed");
    }

}



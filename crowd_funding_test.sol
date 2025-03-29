// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol"; 
import "./crowd_funding.sol";
import "remix_accounts.sol";
import "hardhat/console.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract CrowdFundingTest {
    address acc0 = TestsAccounts.getAccount(0); 
    address acc1 = TestsAccounts.getAccount(1);
    CrowdFunding crowdfunding;

    function beforeEach() public {
        crowdfunding = new CrowdFunding({
                _creator: acc0,
                _goal: 1000,
                _deadline: block.timestamp + 1000,
                _name: "test",
                _description: "test"
            });
    }

    /// ====== constructor test suit ====== /// 

    /// Test initial owner success /// 
    function test_initial_owner_success() public {
        Assert.equal(crowdfunding.creator(), acc0, "init error on creator field");
        Assert.equal(crowdfunding.goal(), 1000, "init error on goal field");
        Assert.equal(crowdfunding.deadline(), block.timestamp + 1000, "init error on deadline field");
        Assert.equal(crowdfunding.name(), "test", "init error on name field");
        Assert.equal(crowdfunding.description(), "test", "init error on description field");
    }

    /// Test initial inital contract address fail /// 
    // not gonna test invalid goal, deadline, name and description
    // I did manually test them should be fine, but feel free to add these tests if you want
    function test_inital_contract_address_fail() public {
        try new CrowdFunding({
            _creator: address(0),
            _goal: 1000,
            _deadline: block.timestamp + 1000,
            _name: "test",
            _description: "test"
        }) {
            Assert.ok(false, "should fail on address zero");
        } catch Error(string memory reason) {
            Assert.equal(reason, "creator shouldn't be invalid address", "Invalid Creator");
        } 
    }

    /// ====== update_campagin_status() test suit ====== ///

    /// Test updating campagin_status to success
    /// #value: 1000
    function test_update_campagin_status_success() public payable{
        crowdfunding.fund{value: 1000}(false);
        Assert.equal(uint(crowdfunding.campaignStatus()), 1, "Status mismatch");
    }

    /// Test updating campagin_status to fail
    // manually test (pass)
    // I believe manually test is needed here since there is no way to adjust the time block (at least not in remix IDE)
    

    /// ====== modifier campaignDeadlineCheck() test suit ====== ///

    /// Test fund after deadline (should fail)
    /// again manually test is needed (pass)


    /// ====== fund() test suite ====== ///

    /// Test zero funding (should fail)
    /// #value: 0
    function test_zero_funding() public payable {
        try crowdfunding.fund{value: 0}(false) {
            Assert.ok(false, "Should fail on zero fund");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Fund amount must larger than 0", "error message should match");
        }
    }

    /// Test flexiable funding (should succeed)
    /// #value: 10
    function test_flexiable_fund() public payable {
        try crowdfunding.fund{value: 10}(true) {
            Assert.ok(true, "Funding succeeded");
        } catch Error(string memory reason) {
            Assert.ok(false, string(abi.encodePacked("Funding failed: ", reason)));
        }

        Assert.equal(crowdfunding.totalFlexibleFunds(), 10, "Flexible Funds not match");
        Assert.equal(crowdfunding.flexibleFundBalance(), 10, "flexibleFundBalance not match");
    }

    /// Test committed funding (should succeed)
    /// #value: 10
    function test_committed_fund() public payable {
        try crowdfunding.fund{value: 10}(false) {
            Assert.ok(true, "Funding succeeded");
        } catch Error(string memory reason) {
            Assert.ok(false, string(abi.encodePacked("Funding failed: ", reason)));
        }

         Assert.equal(crowdfunding.totalCommittedFunds(), 10, "Committed Funds not match");
    }
   

    /// Test flexible fund when campagin is successed (should fail)
    /// #value: 1001
    function test_flexible_fund_when_campagin_is_successed() public payable {
        crowdfunding.fund{value: 1000}(true);

        Assert.equal(uint(crowdfunding.campaignStatus()), 1, "Status mismatch");

        try crowdfunding.fund{value: 1}(true) {
            Assert.ok(false, "Should fail on flexiable fund when campagin is sucessed");
        } catch Error(string memory reason) {
            Assert.equal(reason, "can't not make flexible fund when the campaign is success", "error message should match");
        } 
    }


    /// Test overfunded (should success)
    /// #value: 1001
    function test_overfunded() public payable {
        crowdfunding.fund{value: 1000}(true);

        Assert.equal(uint(crowdfunding.campaignStatus()), 1, "Status mismatch");

        crowdfunding.fund{value: 1}(false);

        Assert.equal(crowdfunding.totalCommittedFunds() + crowdfunding.totalFlexibleFunds(), 1001, "Total fund mismatch");
    }
}
    

//  have to inhertance the contract when testings involve msg.sender
// otherwise we will just use this test contract to call the crowd_funding 
// which mean we can't control the address of msg.sender when calling external function
// since it is inhertance test cases will affect each other so pay attention to the flow
contract CrowdFundingTest2 is CrowdFunding(
                                address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4), //acount-0
                                1000,
                                block.timestamp + 1000,
                                "test",
                                "test"
                            ) {
    
    address acc0 = TestsAccounts.getAccount(0); 
    address acc1 = TestsAccounts.getAccount(1);
    address acc2 = TestsAccounts.getAccount(2);


    /// ====== fund() test suite ====== ///

    /// Test flexiable funding (should succeed)
    /// #value: 10
    /// #sender: account-1
    function test_backer_flexibleFund() public payable {
        fund(true);

        (uint256 flexibleFund, , uint256 joinedDate) = this.backers(acc1);
 
        Assert.equal(flexibleFund, 10, "Backer's Flexible Funds not match");
        Assert.equal(joinedDate, block.timestamp, "Backer's joinedDate not match"); //test joinedDate added or not
        Assert.equal(backerList[0], acc1, "backerlist not added"); // test backerlist added or not
    }


    /// Test flexiable funding (should succeed)
    /// #value: 10
    /// #sender: account-1
    function test_backer_committedFund() public payable {
        fund(false);

        (, uint256 committedFund, ) = this.backers(acc1);
 
        Assert.equal(committedFund, 10, "Backer's committed Funds not match");
    }

    /// Test update of top flexible contributer (should succeed)
    /// #value: 20
    /// #sender: account-2
    function test_update_top_flexible_contributer() public payable {
        fund(true);
        Assert.equal(this.getTopFlexibleContributor(), acc2, "TopFlexibleContributer not match");
    }

    /// ====== refund_flexiable_funds() test suit ====== ///

    /// Test refund_flexiable_funds (should succeed)
    /// require manually test to check sender balance (pass)
    /// #value: 200
    /// #sender: account-2
    function test_refund_flexible_funds() public payable{
        fund(true);
        refund_flexiable_funds(220); // we fund 20 in previous test from acc2
        Assert.equal(this.totalFlexibleFunds(), 10, "Total FlexibleFunds mismatch"); // still have 10 from acc1
        Assert.equal(this.flexibleFundBalance(), 10, "flexibleFundBalance not match");
        Assert.equal(this.getTopFlexibleContributor(), acc1, "TopFlexibleContributer not match"); // should do a loop and get the top flexible contributer
    }

    /// ====== withdraw() test suit ====== ///
    /// Test withdraw_when_success
    /// require manually test (pass)
    /// #value: 1000
    /// #sender: account-0
    function test_withdraw_when_success() public payable{
        fund(true);
        withdraw_remaining_funds();
        Assert.equal(this.totalFlexibleFunds(), 1010, "Total FlexibleFunds mismatch"); //10 from acc1 and 1000 from account 0
        Assert.equal(this.flexibleFundBalance(), 0, " flexibleFundBalance mismatch");
    }

}

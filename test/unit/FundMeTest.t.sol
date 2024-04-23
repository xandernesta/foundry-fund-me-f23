// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // State Variables
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 5e18;
    uint256 constant FAIL_SEND_VALUE = 2e10;
    uint256 constant START_BAL = 10 ether;
    uint256 constant GAS_PRICE = 1;
    function setUp() external {
        // fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, START_BAL);
    }

    function testMinDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
        /* Turns out the vm.startBroadcast is what made this assertion correct since we originally had those in the setUp()
        without those vm. functions it would have errored like Patrick said
         */
        //This test is suppose to fail because we are calling the contract FundMeTest to then call the constructor of FundMe but
        //passes for some reason with our address now
        //Patrick says the test should be written like this instead:
        //assertEq(fundMe.i_owner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //expect the next line to revert or like saying assert(this next tx will fail!)
        fundMe.fund{value: FAIL_SEND_VALUE}();
    }

    function testFundUpdatesAmountFundedDataStructure() public {
        vm.prank(USER); // This makes it so the next TX is sent by USER
        fundMe.fund{value: SEND_VALUE}(); // Value: ~5ETH

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFunder() public funded {
        // in the test above we make sure the first get function works so now lets check getFunders works
        /**
         * taken care of my our funded modifier
         *   vm.prank(USER);
         *   fundMe.fund{value: SEND_VALUE}();
         */
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        /**
         * taken care of my our funded modifier
         *   vm.prank(USER);
         *   fundMe.fund{value: SEND_VALUE}();
         */
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBal = fundMe.getOwner().balance;
        uint256 startingFundMeBal = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBal = fundMe.getOwner().balance;
        uint256 endingFundMeBal = address(fundMe).balance;
        assertEq(endingFundMeBal, 0);
        assertEq(endingOwnerBal, startingOwnerBal + startingFundMeBal);
    }

    function testWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint256 numberOfFunder = 10;
        uint256 startingFunderIndex = 1;
        for (uint256 i = startingFunderIndex; i < numberOfFunder; i++) {
            hoax(address(uint160(i)), START_BAL);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBal = fundMe.getOwner().balance;
        uint256 startingFundMeBal = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner()); // Costs: 200
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBal = fundMe.getOwner().balance;
        uint256 endingFundMeBal = address(fundMe).balance;
        assertEq(endingFundMeBal, 0);
        // or
        assert(address(fundMe).balance == 0);
        assertEq(endingOwnerBal, startingOwnerBal + startingFundMeBal);
    }

    function testCheaperWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint256 numberOfFunder = 10;
        uint256 startingFunderIndex = 1;
        for (uint256 i = startingFunderIndex; i < numberOfFunder; i++) {
            hoax(address(uint160(i)), START_BAL);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBal = fundMe.getOwner().balance;
        uint256 startingFundMeBal = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner()); // Costs: 200
        fundMe.cheaperWithdraw();

        // Assert
        uint256 endingOwnerBal = fundMe.getOwner().balance;
        uint256 endingFundMeBal = address(fundMe).balance;
        assertEq(endingFundMeBal, 0);
        // or
        assert(address(fundMe).balance == 0);
        assertEq(endingOwnerBal, startingOwnerBal + startingFundMeBal);
    }
}

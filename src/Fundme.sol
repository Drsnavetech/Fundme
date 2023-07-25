// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// this is a named import from chainlink.
import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error Fundme_NotOwner();

contract Fundme {
    // this allows us to use the function inside the library for each uint256 as done below.
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;

    address[] private s_funders;
    // mapping of funders and amount funded.
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address pricefeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(pricefeed);
    }

    function fund() public payable {
        require(
            msg.value.convertEthToUsd(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough ETH"
        );
        s_funders.push(msg.sender);
        // addressToAmountFunded[msg.sender] = msg.value; this line if for mapping address to amount funded, but what if the address, funds the contract again,
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // this for loop is to reset the mappings;
        for (uint256 index = 0; index < s_funders.length; index++) {
            address funder = s_funders[index];
            s_addressToAmountFunded[funder] = 0;
        }
        // to reset the list
        s_funders = new address[](0);
        // to withdraw the balance, there are 3 ways
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable (msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // if the underscore appear first, it means, execute the function before the modifier content
        // if as below, the underscore appears after the modifier, the modifier executes first.
        // require(msg.sender == i_owner, "Sender is not owner");
        // this if statement is more gas efficient as it does not need to store the character of the error.
        if (msg.sender != i_owner) {
            revert Fundme_NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // section getters for the view and pure functions

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error FundMe__NotOwner();

import {PriceConverter} from "src/libraries/PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address private immutable I_OWNER;
    AggregatorV3Interface private immutable I_PRICEFEED;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    constructor(address priceFeedAddress) {
        I_OWNER = msg.sender;
        I_PRICEFEED = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(I_PRICEFEED) >= MINIMUM_USD,
            "Fund amount is too low"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;

        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function getVersion() public view returns (uint256) {
        return I_PRICEFEED.version();
    }

    modifier onlyOwner() {
        if (msg.sender != I_OWNER) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return I_OWNER;
    }
}

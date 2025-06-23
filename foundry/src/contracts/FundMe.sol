// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error FundMe__NotOwner();

import {PriceConverter} from "src/libraries/PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address public immutable I_OWNER;
    AggregatorV3Interface private immutable PRICEFEED;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    constructor(address priceFeedAddress) {
        I_OWNER = msg.sender;
        PRICEFEED = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(PRICEFEED) >= MINIMUM_USD,
            "Fund amount is too low"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function getVersion() public view returns (uint256) {
        return PRICEFEED.version();
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // price is gotten from chainlink docs
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // to interact with smart contracts, we need the abi and address.
        // address = 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // abi = gotten from the named import above.
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // this price variable returns the price of eth in terms of usd
        // price has 8 decimal places and an ether has 18 decimals. to make it same decimals, multiply by 1e10.
        // the type-casting done below is because we return uint256 while price is an int256.
        return uint256(price * 1e10);
    }

    function convertEthToUsd(
        uint256 ethAmount,
        AggregatorV3Interface pricefeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(pricefeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}

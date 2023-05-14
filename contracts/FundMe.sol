// SPDX-License-Identifier: MIT

// The contract should have the following functionality
// Smart contract that lets anyone deposit ETH into the contract
// Only the owner of the contract can withdraw the ETH

pragma solidity ^0.6.6;

// Get the latest ETH/USD price from chainlink price feed
// Importing from NPM package/Github
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// The import is not need if we use solidity ^0.8 since it automatically checks for overflow
// import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // keeping track who send us funding
    // create mapping between addresses and value
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // function that gets called the instant our contract gets deployed
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // payable keyword: This function can be used to pay for things
    function fund() public payable {
        // defining a minimum value the user has to fund (setting a threshold)
        uint256 minimumUSD = 50 * 10 ** 18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH"
        );

        // msg.sender: Sender of the function call
        // msg.value: How much they send
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

        // we want a minimum amount people pay in ETH, USD or other currency
        // we need to know what the ETH -> USD conversion rate is
    }

    // calling the version-function from the AggregatorV3Interface (see import)
    // adress ETH/USD priceFeed for Sepolia testnet from Chainlink docs
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // calling the price-function from the AggregatorV3Interface (see import)
    // price in wei
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // function that converts the ETH send to the contract to USD
    function getConversionRate(
        uint256 ethAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10 ** 18;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price);
    }

    // creating a modifier
    modifier onlyOwner() {
        // only the contract admin/owner should be able to withdraw
        // require msg.sender == owner
        require(msg.sender == owner);
        _;
    }

    // Withdraw function to get deposited funds from the contract
    function withdraw() public payable onlyOwner {
        // differs from the sample code, since there was an update from "address" to "address payable"
        // see: https://ethereum.stackexchange.com/questions/87153/typeerror-send-and-transfer-are-only-available-for-objects-of-type-address
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

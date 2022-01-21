# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

## Dependencies
* `node 14.18.1 (lts/fermium)`
* `truffle v5.4.26`
* `Solidity - ^0.4.25`
* `web3.js v1.7.0`

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

## Ganache Desktop

This repository is configured to listen to port `7545`. A workspace with 50 accounts with a respective balance of 5000 ETH is recommended to run this project.

## Develop Client

To run truffle tests:

`truffle test ./test/TestContracts.js`
`truffle test ./test/TestOracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

## Develop Server

20 oracles are registered by default when launching the server. They respectively correspond to the `web3.eth.account[20]` - `web3.eth.account[39]` accounts. 

`npm run server`
`truffle test ./test/TestOracles.js`

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder

## To use the Dapp

When the contract is first deployed, a first airline associated with `web3.eth.account[1]` is registered and funded. You can use this address in the `From Airline` field. Then, you can add a second airline for a new airline to be registered and funded. Status for registration and funding can also be accessed. Both address fields need to completed for this to work.

Similarly, a new flight can be registered by adding a registered airline to the `Flight Airline` field. A `Flight Number` and `Flight Time` with the following format (`2023-01-01 09:00:00`) are also required. The flight can therefore be registered and submitted to oracles to fetch a new status code. This newly fetched status code be afterwards be accessed with the `Get Flight Status Code` button.

Finally, you can provide a passenger address to buy an insurance to a registered flight, based on the information provided in the `Register Flight` section above. The insurance amount in specified in the `Insurance Amount` field. If the flight status code fetched is equal to `20`, it means that the flight is late because of the airline, and the passenger can redeem his money using the `Withdraw Credits` button.
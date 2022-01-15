const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');
const Web3 = require('web3');

// const Web3 = require('web3');

// let w3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'));

/**
 * Inspiration from yuryprokashev's repo (https://github.com/yuryprokashev/flight-surety)
 * and this article on contract deployment (https://betterprogramming.pub/how-to-write-complex-truffle-migrations-86d4b85d7783)
 * and https://ethereum.stackexchange.com/questions/67487/solidity-truffle-call-contract-function-in-migration-file
 */
module.exports = async function(deployer, network, accounts) {
    let firstAirline = accounts[0];
    let fund = Web3.utils.toWei("10","ether");
    await deployer.deploy(FlightSuretyData, firstAirline, {from:firstAirline, value:fund});
    await deployer.deploy(FlightSuretyApp, FlightSuretyData.address);
    
    let dataContract = await FlightSuretyData.deployed();
    await dataContract.setAuthorizedCaller(FlightSuretyApp.address);
    
    let config = {
        localhost: {
            url: 'http://localhost:7545',
            dataAddress: FlightSuretyData.address,
            appAddress: FlightSuretyApp.address
        }
    }
    fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
    fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
}
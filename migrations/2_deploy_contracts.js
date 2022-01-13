const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');
const Web3 = require('web3');

let w3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'));

module.exports = async function(deployer, network, accounts) {
    let firstAirline = accounts[0];
    await deployer.deploy(FlightSuretyData, firstAirline, {from:firstAirline, value:w3.utils.toWei("0.001", "ether")});
    await deployer.deploy(FlightSuretyApp, FlightSuretyData.address);
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
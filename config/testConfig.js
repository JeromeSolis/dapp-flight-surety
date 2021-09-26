
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0xaf8906f7F293d901cc88FeE7EE5166267313D286",
        "0x43E9e1f43e7d1471c28294547Bb48B4D0CbaF83f",
        "0xF3d16F97D008493679Db410FF07241C33DC1E044",
        "0xc066d5884afE6Dc083C3A3C520E3dDF9a16C637A",
        "0x2Bb710FdA82Cd0Edb3863E9Cb634cEFBD70b392B",
        "0x48529E11695175699DE4998AC141361E6d6c4c29",
        "0x81fE0c9Ab7E3b3BebfC32A8a01A39596c4D536c1",
        "0xc5D91252d2CaFd5c52b1Ac8ae09F6dEFEcE857fd",
        "0x7689cFE3F03fD4164B187aa4edE81E5721D4C1e0"
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];

    let flightSuretyData = await FlightSuretyData.new();
    let flightSuretyApp = await FlightSuretyApp.new();

    
    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};
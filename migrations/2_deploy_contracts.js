const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = function(deployer) {
    let firstAirline = '0xaf8906f7F293d901cc88FeE7EE5166267313D286';
    deployer.deploy(FlightSuretyData).then(() => {
        return deployer.deploy(FlightSuretyApp, FlightSuretyData.address, firstAirline);
    }).then(() => {
        let config = {
            localhost: {
                url: 'http://localhost:7545',
                dataAddress: FlightSuretyData.address,
                appAddress: FlightSuretyApp.address
            }
        }
        fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
        fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
    });
}
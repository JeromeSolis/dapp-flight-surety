
// var Test = require('../config/testConfig.js');
//var BigNumber = require('bignumber.js');
const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const Web3 = require('web3');


contract('Oracles', async (accounts) => {

  const TEST_ORACLES_COUNT = 20;
  // var config;
  const contractOwner = accounts[0];
  const firstAirline = accounts[1];
  const fund = Web3.utils.toWei("10","ether");

  let flightSuretyData, flightSuretyApp;

  before('setup contract', async () => {
    // config = await Test.Config(accounts);

    flightSuretyData = await FlightSuretyData.new(firstAirline, {from:contractOwner, value:fund});
    flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address, {from:contractOwner})
    try {
      await flightSuretyData.setAuthorizedCaller(flightSuretyApp.address, {from:contractOwner});
    } catch (err) {
      console.log(err);
    }

    // Watch contract events
    const STATUS_CODE_UNKNOWN = 0;
    const STATUS_CODE_ON_TIME = 10;
    const STATUS_CODE_LATE_AIRLINE = 20;
    const STATUS_CODE_LATE_WEATHER = 30;
    const STATUS_CODE_LATE_TECHNICAL = 40;
    const STATUS_CODE_LATE_OTHER = 50;

  });


  it('can register oracles', async () => {
    
    // ARRANGE
    let fee = await flightSuretyApp.REGISTRATION_FEE.call();

    // ACT
    for(let a=1; a<TEST_ORACLES_COUNT; a++) {      
      await flightSuretyApp.registerOracle({ from: accounts[a], value: fee });
      let result = await flightSuretyApp.getMyIndexes.call({from: accounts[a]});
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
    }

  });

  it('can request flight status', async () => {
    
    // ARRANGE
    let flight = 'ND1309'; // Course number
    let timestamp = Math.floor(Date.now() / 1000);
    await flightSuretyApp.registerFlight(flight, timestamp, {from:firstAirline});
    let status = await flightSuretyApp.isRegisteredFlight(firstAirline, flight, timestamp);

    assert(status, true, "Flight wasn't properly registered");

    // Submit a request for oracles to get status information for a flight
    await flightSuretyApp.fetchFlightStatus(firstAirline, flight, timestamp);
    // ACT

    // Since the Index assigned to each test account is opaque by design
    // loop through all the accounts and for each account, all its Indexes (indices?)
    // and submit a response. The contract will reject a submission if it was
    // not requested so while sub-optimal, it's a good test of that feature
    for(let a=1; a<TEST_ORACLES_COUNT; a++) {

      // Get oracle information
      let oracleIndexes = await flightSuretyApp.getMyIndexes.call({from:accounts[a]});
      for(let idx=0;idx<3;idx++) {

        try {
          // Submit a response...it will only be accepted if there is an Index match
          await flightSuretyApp.submitOracleResponse(oracleIndexes[idx], firstAirline, flight, timestamp, STATUS_CODE_ON_TIME, { from: accounts[a] });

        }
        catch(e) {
          // Enable this when debugging
           console.log('\nError', idx, oracleIndexes[idx].toNumber(), flight, timestamp);
        }

      }
    }


  });


 
});

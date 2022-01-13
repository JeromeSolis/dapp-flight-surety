var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');


contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.setAuthorizedCaller(config.flightSuretyApp.address, {from: config.owner});
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call({from: config.owner});
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`First airline was properly registered`, async function() {
    let (airlineId , registeredStatus, fundedStatus) = await config.flightSuretyData.getAirline(config.firstAirline, {from: config.owner});
    assert.equal(registeredStatus, true, "First airline wasn't registered")
  });

  it(`First airline was properly funded`, async function() {
    let (airlineId , registeredStatus, fundedStatus) = await config.flightSuretyData.getAirline(config.firstAirline, {from: config.owner});
    assert.equal(fundedStatus, true, "First airline wasn't funded")
  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

    // Ensure that access is allowed for Contract Owner account
    let accessDenied = false;

    try {
        await config.flightSuretyData.setOperatingStatus(false, {from: config.owner});
    } catch(e) {
        accessDenied = true;
    }
    assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

    await config.flightSuretyData.setOperatingStatus(false, {from: config.owner});

    let reverted = false;
    let testAirline = accounts[2];

    try {
        await config.flightSuretyApp.registerAirline(testAirline, {from: flightSuretyApp.address});
    }
    catch(e) {
        reverted = true;
    }
    assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

    // Set it back for other tests to work
    await config.flightSuretyData.setOperatingStatus(true, {from: config.owner});
  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    } catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });
});

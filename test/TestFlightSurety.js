// var Test = require('../config/testConfig.js');
// var BigNumber = require('bignumber.js');
const Web3 = require('web3');

const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");

contract('Flight Surety Tests', accounts => {

  const contractOwner = accounts[0];
  const firstAirline = accounts[1];
  // const fund = 10 * (new BigNumber(10)).pow(18);
  const fund = Web3.utils.toWei("10","ether");

  let testAddresses = [
    "0x69e1CB5cFcA8A311586e3406ed0301C06fb839a2",
    "0xF014343BDFFbED8660A9d8721deC985126f189F3",
    "0x0E79EDbD6A727CfeE09A2b1d0A59F7752d5bf7C9",
    "0x9bC1169Ca09555bf2721A5C9eC6D69c8073bfeB4",
    "0xa23eAEf02F9E0338EEcDa8Fdd0A73aDD781b2A86",
    "0x6b85cc8f612d5457d49775439335f83e12b8cfde",
    "0xcbd22ff1ded1423fbc24a7af2148745878800024",
    "0xc257274276a4e539741ca11b590b9447b26a8051",
    "0x2f2899d6d35b1a48a4fbdc93a37a72f264a9fca7"
  ];

  let flightSuretyData, flightSuretyApp;
  // var config;

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  describe('Test operational status control implementation', async function () {

    before('setup contract', async function () {

      flightSuretyData = await FlightSuretyData.new(firstAirline, {from:contractOwner, value:fund});
      flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address, {from:contractOwner})
      try {
        await flightSuretyData.setAuthorizedCaller(flightSuretyApp.address, {from:contractOwner});
      } catch (err) {
        console.log(err);
      }
      // await config.flightSuretyData.setAuthorizedCaller(config.flightSuretyApp.address, {from: config.owner});
      // config = await Test.Config(accounts);
    });

    afterEach(async () => {
      // Set back operational status to true after each test
      await flightSuretyData.setOperatingStatus(true, {from:contractOwner});
    });

    it(`(multiparty) has correct initial isOperational() value for data contract`, async function () {
      // Get operating status
      let status = await flightSuretyData.isOperational({from:contractOwner});
      assert.equal(status, true, "Incorrect initial operating status value");
    });

    it(`(multiparty) has correct initial isOperational() value for app contract`, async function () {
      // Get operating status
      let status = await flightSuretyApp.isOperational({from:contractOwner});
      assert.equal(status, true, "Incorrect initial operating status value");
    });

    it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {
      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try {
          await flightSuretyData.setOperatingStatus(false, {from:testAddresses[2]});
      } catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");        
    });

    it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {
      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try {
          await flightSuretyData.setOperatingStatus(false, {from:contractOwner});
      } catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
    });

    it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await flightSuretyData.setOperatingStatus(false, {from:contractOwner});
  
      let reverted = false;
      let testAirline = accounts[2];
  
      try {
          await config.flightSuretyApp.registerAirline(testAirline, {from:flightSuretyApp.address});
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      
    });
  })

  describe('Test airline functionality', async function () {

    before(async () => {
      // Resetting contract state
      flightSuretyData = await FlightSuretyData.new(firstAirline, {from:contractOwner, value:fund});
      flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address, {from:contractOwner})
      try {
        await flightSuretyData.setAuthorizedCaller(flightSuretyApp.address, {from:contractOwner});
        console.log('New contracts instantiated');
      } catch (err) {
        console.log(err);
      }
    })

    it(`(Airline Contract Initialization) First airline was properly registered`, async function() {
      // Get first airline
      let airline = await flightSuretyApp.getAirline(firstAirline, {from:contractOwner});
      assert.equal(airline[1], true, "First airline wasn't registered")
    });

    it(`(Airline Contract Initialization) First airline was properly funded`, async function() {
      let airline = await flightSuretyApp.getAirline(firstAirline, {from:contractOwner});
      assert.equal(airline[2], true, "First airline wasn't funded")
    });

    describe('(Multiparty Concensus)', async function () {

      

      it('Only existing airline may register a new airline until there are at least four airlines registered', async () => {
        // ARRANGE
        let secondAirline = accounts[2];
        let thirdAirline = accounts[3];
        let fourthAirline = accounts[4];
        let fifthAirline = accounts[5];
        // ACT
        try {
            await flightSuretyApp.registerAirline(secondAirline, {from:firstAirline});
            await flightSuretyApp.fundAirline({from:secondAirline, value:fund});
            await flightSuretyApp.registerAirline(thirdAirline, {from:secondAirline});
            await flightSuretyApp.fundAirline({from:thirdAirline, value:fund});
            await flightSuretyApp.registerAirline(fourthAirline, {from:thirdAirline});
            await flightSuretyApp.fundAirline({from:fourthAirline, value:fund});
            await flightSuretyApp.registerAirline(fifthAirline, {from:fourthAirline});
        } catch(err) {
          // console.log(err);
        }
        const result2 = await flightSuretyApp.getAirline(secondAirline);
        const result3 = await flightSuretyApp.getAirline(thirdAirline); 
        const result4 = await flightSuretyApp.getAirline(fourthAirline); 
        const result5 = await flightSuretyApp.getAirline(fifthAirline);  
        // ASSERT
        assert.equal(result2[1], true, "Airline 2 should be able to register another airline if it has provided funding");
        assert.equal(result3[1], true, "Airline 3 should be able to register another airline if it has provided funding");
        assert.equal(result4[1], true, "Airline 4 should be able to register another airline if it has provided funding");
        assert.equal(result5[1], false, "Airline 5 should not be able to register another airline if it hasn't provided funding");
      });
    });   

    describe('(Airline Ante) Airline cannot register an new airline using registerAirline() if it is not funded', async function () {
      
      beforeEach(async () => {
        // Resetting contract state
        flightSuretyData = await FlightSuretyData.new(firstAirline, {from:contractOwner, value:fund});
        flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address, {from:contractOwner})
        await flightSuretyData.setAuthorizedCaller(flightSuretyApp.address, {from:contractOwner});
      });
      
      it('cannot register an new airline if it is not funded', async () => {
        // ARRANGE
        let newAirline = accounts[2];
        let newestAirline = accounts[3];
        // ACT
        try {
            await flightSuretyApp.registerAirline(newAirline, {from:firstAirline});
            await flightSuretyApp.registerAirline(newestAirline, {from:newAirline});
        } catch(err) {
          console.log(err);
        }
        const result = await flightSuretyApp.getAirline(newestAirline); 
        // ASSERT
        assert.equal(result[1], false, "Airline should not be able to register another airline if it hasn't provided funding");
      });
  
      it('can register an new airline if it is funded', async () => {
        // ARRANGE
        let newAirline = accounts[2];
        let newestAirline = accounts[3];
        // ACT
        try {
            await flightSuretyApp.registerAirline(newAirline, {from:firstAirline});
            await flightSuretyApp.fundAirline({from:newAirline, value:fund});
            await flightSuretyApp.registerAirline(newestAirline, {from:newAirline});
        } catch(err) {
          console.log(err);
        }
        const result = await flightSuretyApp.getAirline(newestAirline); 
        // ASSERT
        assert.equal(result[1], true, "Airline should be able to register another airline if it has provided funding");
      });
    });
  });
});

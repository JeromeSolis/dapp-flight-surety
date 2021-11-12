pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                               // Account used to deploy contract
    bool private operational;                                    // Blocks all state changes throughout the contract if false
    
    uint256 private airlineThreshold;
    uint256 private airlineCount;
    address[] votes = new address[](0);
    // address[] votesOperational = new address[](0);

    struct Airline {
        bool isRegistered;
        bool isVoter;
    }

    struct Insurance {
        bytes32 flightId;
        uint256 amountPaid;
        address owner;
    }

    struct Caller {
        bool isAuthorized; 
    }

    struct Flight {
        bool isRegistered;
        string flight;
        address airline;
        uint256 flightTimestamp;
        uint8 flightStatus;
    }

    mapping(address => Airline) private airlines;
    mapping(address => Insurance) private insurances;
    mapping(bytes32 => Flight) private flights;
    mapping(address => Caller) private callers;

    uint256 private constant FEE_AIRLINE_REGISTRATION = 10 ether;
    uint256 private constant MAX_INSURANCE_POLICY = 1 ether;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public payable {
        contractOwner = msg.sender;
        operational = true;
        airlineCount = 0;
        
        callers[address(this)].isAuthorized = true;
        callers[contractOwner].isAuthorized = true;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAuthorizedCaller() {
        require(callers[msg.sender].isAuthorized, "Caller is not authorized");
        _;
    }
    

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) {
        return operational;
    }

     /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */

    // Contracts functions

    function setOperatingStatus(bool _mode) external requireContractOwner {
        // require(_mode != operational, "No change in mode detected");
        // require(airlines[msg.sender].isAdmin, "Caller is not an admin");

        // bool isDuplicate = false;
        // for(uint256 i=0; i<votesOperational.length; i++) {
        //     if (votesOperational[i] == msg.sender) {
        //         isDuplicate = true;
        //         break;
        //     }
        // }
        // require(!isDuplicate, "Caller has already called this function.");

        // votesOperational.push(msg.sender);
        // if (votesOperational.length >= airlineThreshold.sub(1)) {
        //     operational = _mode;      
        //     votesOperational = new address[](0);      
        // }
        operational = _mode;
    }

    function authorizeCaller(address _contractAddress, bool _status) external requireContractOwner requireIsOperational {
        callers[_contractAddress].isAuthorized = _status;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    
    // Airline functions

    function isAirline(address _address) public view returns(bool) {
        return airlines[_address].isVoter;
    }

    function isRegisteredAirline(address _address) public view returns(bool) {
        return airlines[_address].isRegistered;
    }

    function getRegistrationFee() public pure returns(uint256) {
        return FEE_AIRLINE_REGISTRATION;
    }

    function getAirlineCount() public view returns(uint256) {
        return airlineCount;
    }

    function registerAirline(address _airline) external requireIsOperational requireAuthorizedCaller {
        airlines[_airline].isRegistered = true;
        airlines[_airline].isVoter = false;
        airlineCount = airlineCount.add(1);
    }

    // Flight functions

    function isRegisteredFlight(bytes32 _key) public view returns(bool) {
        return flights[_key].isRegistered;
    }

    function getFlight(bytes32 _key) public view returns(bool, string, address, uint256, uint8) {
        return (flights[_key].isRegistered, flights[_key].flight, flights[_key].airline, flights[_key].flightTimestamp, flights[_key].flightStatus);
    }

    function registerFlight(address _airline, string _flight, uint256 _timestamp, uint8 _status) external requireIsOperational requireAuthorizedCaller {
        bytes32 key = getFlightKey(_airline, _flight, _timestamp);
        flights[key] = Flight({
            isRegistered: true,
            flight: _flight,
            airline: _airline,
            flightTimestamp: _timestamp,
            flightStatus: _status
        });
    }


    // Insurance functions
   /**
    * @dev Buy insurance for a flight
    *
    */

    function registerInsurance(bytes32 _flightKey, uint256 _amount, address _owner) external requireIsOperational requireAuthorizedCaller {
        insurances[msg.sender] = Insurance({
            flightId: _flightKey,
            amountPaid: _amount,
            owner: _owner
        });
    }

    function buy(bytes32 _flightKey) external payable requireIsOperational {
        require(msg.value <= MAX_INSURANCE_POLICY, "Value of insurance too high");

        address(this).transfer(msg.value);
        insurances[msg.sender] = Insurance({
            flightId: _flightKey,
            amountPaid: msg.value,
            owner: msg.sender
        });
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(address _account) external requireIsOperational {
        uint256 amountPaid = insurances[_account].amountPaid;
        uint256 insuranceToPay = amountPaid.mul(15).div(10);
        insurances[_account].amountPaid = 0;
    }
    
    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(address _account, uint256 _amount) external payable requireIsOperational {
        _account.transfer(_amount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund() public payable requireIsOperational {
        require(msg.value >= FEE_AIRLINE_REGISTRATION, "Insufficiant funds");
        require(airlines[msg.sender].isRegistered, "Airline not yet registered");
        // require(!airlines[msg.sender].isVoter, "Airline is already a voter");

        address(this).transfer(msg.value);
        airlines[msg.sender].isVoter = true;
    }

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
        fund();
    }
}


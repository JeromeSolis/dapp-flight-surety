pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational;                                    // Blocks all state changes throughout the contract if false
    mapping (address => bool) private authorizedCaller;

    struct Airline {
        uint256 airlineId;
        bool isRegistered;
        bool isFunded;
    }
    mapping (address => Airline) private airlines;
    uint256 private airlineCount = 0;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping (bytes32 => Flight) private flights;

    struct Insurance {
        address insuree;
        bytes32 flightKey;
        uint256 amount;
    }
    mapping (address => Insurance[]) private insurancesPerInsuree;
    mapping (bytes32 => Insurance[]) private insurancesPerFlight;

    mapping(address => uint256) private creditedAmounts;

    uint256 private constant AIRLINE_REGISTRATION_FEE = 10 ether;
    uint256 private constant MAX_INSURANCE_FEE = 1 ether;
    uint256 private constant MULTIPARTY_THRESHOLD = 4;
    uint256 private constant NUM_INSURANCE_MULTIPLIER = 3;
    uint256 private constant DENUM_INSURANCE_MULTIPLIER = 2;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event AirlineRegistered(uint256 airlineCount, address airlineAddress);
    event AirlineFunded(address airlineAddress);
    event AuthorizedCallerAdded(address caller);
    event FundsAdded(address receiver, uint256 amount, address payer);
    event PaidAmount(address receiver, uint256 amount);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(address firstAirline) public payable {
        operational = true;
        contractOwner = msg.sender;
        // address firstAirline = msg.sender;
        
        authorizedCaller[contractOwner] = true;
        authorizedCaller[address(this)] = true;

        airlineCount = airlineCount.add(1);
        airlines[firstAirline] = Airline({airlineId: airlineCount, isRegistered:true, isFunded: true});
        emit AirlineRegistered(airlineCount, firstAirline);

        address(this).transfer(msg.value);
        emit AirlineFunded(firstAirline);

        authorizedCaller[firstAirline] = true;
        emit AuthorizedCallerAdded(firstAirline);
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

    modifier requireIsAuthorizedCaller() {
        require(isAuthorizedCaller(msg.sender), "Caller is not authorized");
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
    function isOperational() public view returns (bool) {
        return operational;
    }

    function isAuthorizedCaller(address caller) public view returns (bool) {
        return authorizedCaller[caller];
    }

    function isRegisteredAirline(address airline) public view returns (bool) {
        return airlines[airline].isRegistered;
    }

    function isFundedAirline(address airline) public view returns (bool) {
        return airlines[airline].isFunded;
    }

    function isRegisteredFlight(bytes32 flightKey) public view returns (bool) {
        return flights[flightKey].isRegistered;
    }

    function isInsured(address insuree, bytes32 flightKey) public view returns (bool) {
        bool insuranceStatus = false;
        for (uint256 i=0; i< insurancesPerInsuree[insuree].length; i++) {
            if (insurancesPerInsuree[insuree][i].flightKey == flightKey && insurancesPerInsuree[insuree][i].amount > 0) {
                insuranceStatus = true;
            }
        }
        return insuranceStatus;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function setAuthorizedCaller(address caller) public {
        authorizedCaller[caller] = true;
    }

    function getAirlineRegistrationFee() public view returns (uint256) {
        return AIRLINE_REGISTRATION_FEE;
    }
    
    function getMaxInsuranceFee() public view returns (uint256) {
        return MAX_INSURANCE_FEE;
    }

    function getMultipartyThreshold() public view returns (uint256) {
        return MULTIPARTY_THRESHOLD;
    }

    function getAirlineCount() public view returns (uint256) {
        return airlineCount;
    }

    function getAirline(address airlineAddress) requireIsOperational public view returns (uint256 airlineId, bool isRegistered, bool isFunded) {
        return (
            airlines[airlineAddress].airlineId, 
            airlines[airlineAddress].isRegistered, 
            airlines[airlineAddress].isFunded
        );
    }

    function getFlight(bytes32 flightKey) requireIsOperational public view returns (bool isRegistered, uint8 statusCode, uint256 updatedTimestamp, address airline) {
        return (
            flights[flightKey].isRegistered,
            flights[flightKey].statusCode,
            flights[flightKey].updatedTimestamp,
            flights[flightKey].airline
        );
    }

    function getFlightStatus(bytes32 flightKey) requireIsOperational public view returns (uint8 statusCode) {
        return flights[flightKey].statusCode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */

    function addAirline(address airline) external requireIsOperational requireIsAuthorizedCaller {
        require(airlines[airline].airlineId == 0, "Airline already created");

        airlineCount = airlineCount.add(1);
        airlines[airline] = Airline({airlineId: airlineCount, isRegistered:true, isFunded: false});
    }

    function setAirlineFunded(address airline) external requireIsOperational requireIsAuthorizedCaller {
        require(airlines[airline].isRegistered == true, "Airline isn't registered yet");
        require(airlines[airline].isFunded == false, "Airline is already funded");

        airlines[airline].isFunded == true;
    }

    function addFlight(address airline, string flight, uint256 timestamp) external requireIsOperational requireIsAuthorizedCaller {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        require(!flights[flightKey].isRegistered, "Flight already registered");

        flights[flightKey] = Flight({isRegistered:true, statusCode:0, updatedTimestamp:timestamp, airline:airline});
    }

    function updateFlight(address airline, string flight, uint256 timestamp, uint8 statusCode) external requireIsOperational requireIsAuthorizedCaller {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        require(flights[flightKey].isRegistered, "Flight is not registered yet");

        flights[flightKey].statusCode = statusCode;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function addInsurance(address insuree, bytes32 flightKey, uint256 amount) external requireIsOperational requireIsAuthorizedCaller {
        insurancesPerInsuree[insuree].push(Insurance({insuree:insuree, flightKey:flightKey, amount:amount}));
        insurancesPerFlight[flightKey].push(Insurance({insuree:insuree, flightKey:flightKey, amount:amount}));
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 flightKey) external requireIsOperational requireIsAuthorizedCaller {
        // require(isInsured(insuree, flightKey), "Caller didn't purchased an insurance for this flight");

        for (uint256 i=0; i<insurancesPerFlight[flightKey].length; i++) {
            address creditedInsuree = insurancesPerFlight[flightKey][i].insuree;
            uint256 creditedAmount = insurancesPerFlight[flightKey][i].amount.mul(NUM_INSURANCE_MULTIPLIER).div(DENUM_INSURANCE_MULTIPLIER);
            creditedAmounts[creditedInsuree] = creditedAmounts[creditedInsuree].add(creditedAmount);
        }
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function payInsuree(address insuree, uint256 amount) external payable requireIsOperational requireIsAuthorizedCaller {
        require(amount <= creditedAmounts[insuree], "Withdrawn amount is highed than available credit");
        require(amount <= address(this).balance, "Insufficient fund in contract");

        creditedAmounts[insuree] = creditedAmounts[insuree].sub(amount);
        insuree.transfer(amount);
        emit PaidAmount(insuree, amount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund(address airline) public payable requireIsAuthorizedCaller {
        require(airlines[airline].isRegistered, "Airline isn't registered");
        require(airlines[airline].isFunded == false, "Airline already funded");
        
        address(this).transfer(msg.value);
    }

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
        emit FundsAdded(address(this), msg.value, msg.sender);
    }
}
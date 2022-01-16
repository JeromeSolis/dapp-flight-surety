pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Data Contract
    FlightSuretyData flightSuretyData;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract
    address[] votes = new address[](0);
    bool private operational;

    struct Airline {
        uint256 airlineId;
        bool isRegistered;
        bool isFunded;
    }

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AirlineRegistered(uint256 airlineCount, address airlineAddress);
    event AirlineFunded(address airlineAddress);
    event AirlineVoteRegistered(address airlineCandidate, address airlineVoter);
    event AuthorizedCallerAdded(address caller);
    event InsurancePurchased(address insuree, address airline, string flight, uint256 timestamp);

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
         // Modify to call data contract's status
        require(isOperational(), "Contract is currently not operational");  
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

    modifier requireIsRegisteredAirline() {
        require(isRegisteredAirline(msg.sender), "Caller is not a registered airline");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address dataContract) public {
        operational = true;
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns (bool) {
        return operational;  // Modify to call data contract's status
    }

    function isAuthorizedCaller(address caller) public view returns (bool) {
        return flightSuretyData.isAuthorizedCaller(caller);
    }

    function isRegisteredAirline(address airline) public view returns (bool) {
        return flightSuretyData.isRegisteredAirline(airline);
    }

    function isFundedAirline(address airline) public view returns (bool) {
        return flightSuretyData.isFundedAirline(airline);
    }

    function isRegisteredFlight(bytes32 flightKey) public view returns (bool) {
        return flightSuretyData.isRegisteredFlight(flightKey);
    }

    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function setAuthorizedCaller(address caller) private {
        flightSuretyData.setAuthorizedCaller(caller);

        emit AuthorizedCallerAdded(caller);
    }

    function getAirline(address airlineAddress) public view returns (uint256 airlineId, bool isRegistered, bool isFunded) {
        return flightSuretyData.getAirline(airlineAddress);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline(address airlineAddress) requireIsOperational requireIsAuthorizedCaller public {
        uint256 airlineCount = flightSuretyData.getAirlineCount();
        uint256 threshold = flightSuretyData.getMultipartyThreshold();

        if (airlineCount < threshold) {
            flightSuretyData.addAirline(airlineAddress);
            emit AirlineRegistered(airlineCount.add(1), airlineAddress);
        } else {
            bool isDuplicate = false;
            for (uint256 i=0; i<votes.length; i++) {
                if (votes[i] == msg.sender) {
                    isDuplicate = true;
                    break;
                }
            }
            require(!isDuplicate, "Caller has already called this function.");

            votes.push(msg.sender);
            emit AirlineVoteRegistered(airlineAddress, msg.sender);

            if (votes.length >= airlineCount.div(2)) {
                flightSuretyData.addAirline(airlineAddress);
                emit AirlineRegistered(airlineCount.add(1), airlineAddress);
                votes = new address[](0);
            }
        }
    }

    function fundAirline() requireIsOperational requireIsRegisteredAirline external payable {

        uint256 registrationFee = flightSuretyData.getAirlineRegistrationFee();
        require(msg.value >= registrationFee, "Payment doesn't meet minimum value");

        address(flightSuretyData).transfer(msg.value);
        flightSuretyData.setAirlineFunded(msg.sender);
        emit AirlineFunded(msg.sender);

        setAuthorizedCaller(msg.sender);
    }


   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight(string flightName, uint256 timestamp) external requireIsOperational requireIsAuthorizedCaller {
        require(timestamp > block.timestamp, "Flight has already departed");

        flightSuretyData.addFlight(msg.sender, flightName, timestamp);
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode) internal requireIsOperational requireIsAuthorizedCaller {
        flightSuretyData.updateFlight(airline, flight, timestamp, statusCode);
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address airline, string flight, uint256 timestamp) external {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({requester: msg.sender, isOpen: true});

        emit OracleRequest(index, airline, flight, timestamp);
    }

    function buyInsurance(address airline, string flight, uint256 timestamp) external payable requireIsOperational {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);

        require(msg.value <= 1 ether, "Payment is too high");
        require(isFundedAirline(airline), "Airline is not funded");
        require(isRegisteredFlight(flightKey), "Flight is not registered");
    
        address(flightSuretyData).transfer(msg.value);
        flightSuretyData.addInsurance(msg.sender, flightKey, msg.value);
        emit InsurancePurchased(msg.sender, airline, flight, timestamp);
    }


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes() view external returns (uint8[3]) {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(uint8 index, address airline, string flight, uint256 timestamp, uint8 statusCode) external {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey(address airline, string flight, uint256 timestamp) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns (uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }
}

contract FlightSuretyData {
    function isAuthorizedCaller(address caller) public view returns (bool);
    function isRegisteredAirline(address airline) public view returns (bool);
    function isFundedAirline(address airline) public view returns (bool);
    function isRegisteredFlight(bytes32 flightKey) public view returns (bool);
    function setAuthorizedCaller(address caller) external;
    function getMultipartyThreshold() public view returns (uint256);
    function getAirlineRegistrationFee() public view returns (uint256);
    function getAirlineCount() public view returns (uint256);
    function getAirline(address airlineAddress) public view returns (uint256 airlineId, bool isRegistered, bool isFunded);
    function setAirlineFunded(address airline) external;
    function addAirline(address airlineAddress) external;
    function addFlight(address airline, string flightName, uint256 timestamp) external;
    function updateFlight(address airline, string flightName, uint256 timestamp, uint8 statusCode) external;
    function addInsurance(address insuree, bytes32 flightKey, uint256 amount) external;
}
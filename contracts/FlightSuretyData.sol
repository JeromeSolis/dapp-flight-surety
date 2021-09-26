pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                               // Account used to deploy contract
    bool private operational;                                    // Blocks all state changes throughout the contract if false
    
    uint256 private airlinesThreshold;
    uint256 private airlinesCount;
    address[] votesRegister = new address[](0);
    address[] votesOperational = new address[](0);

    struct Airline {
        bool isRegistered;
        bool isAdmin;
        bool isVoter;
    }

    struct Insurance {
        uint256 flightId;
        uint256 amountPaid;
        address owner;
    }

    struct Passenger {
        uint256 balance; 
        address wallet;
    }

    struct Flight {
        string flight;
        bytes32 key;
        address airline;
        uint256 flightTimestamp;
        uint8 flightStatus;
    }

    mapping(address => Airline) private airlines;
    mapping(address => Insurance) private insurances;
    mapping(bytes32 => Flight) private flights;

    uint256 private registrationFee;
    uint256 private insuranceFee;

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
        airlinesCount = 0;
        
        airlinesCount = airlinesCount.add(1);
        airlines[contractOwner] = Airline({isRegistered: true, isAdmin: true, isVoter: true});
        
        registrationFee = 25 ether;
        insuranceFee = 1 ether;

        // address(this).transfer(msg.value); // Fund contract upon creation
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
    function setOperatingStatus(bool _mode) external requireContractOwner {
        require(_mode != operational, "No change in mode detected");
        require(airlines[msg.sender].isAdmin, "Caller is not an admin");

        bool isDuplicate = false;
        for(uint256 i=0; i<votesOperational.length; i++) {
            if (votesOperational[i] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Caller has already called this function.");

        votesOperational.push(msg.sender);
        if (votesOperational.length >= airlinesThreshold.sub(1)) {
            operational = _mode;      
            votesOperational = new address[](0);      
        }
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline(address _account) external requireIsOperational {
        require(airlines[msg.sender].isRegistered, "Caller not registered");

        if (airlinesCount <= airlinesThreshold) {
            airlinesCount = airlinesCount.add(1);
            airlines[_account] = Airline({
                isRegistered: true,
                isAdmin: true,
                isVoter: true
            });
        } else {
            bool isDuplicate = false;
            for (uint256 i=0; i<airlinesCount; i++) {
                if (votesRegister[i] == msg.sender) {
                    isDuplicate = true;
                    break;
                }
            }
            require(!isDuplicate, "Caller has already called this function.");

            votesRegister.push(msg.sender);
            if (votesRegister.length >= airlinesCount.div(2)) {
                airlinesCount = airlinesCount.add(1);
                airlines[_account] = Airline({
                    isRegistered: true,
                    isAdmin: false,
                    isVoter: false
                });
                votesRegister = new address[](0);
            }
        }
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy(uint256 _flightKey) external payable requireIsOperational {
        require(msg.value <= insuranceFee, "Value of insurance too high");

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
        require(msg.value >= registrationFee, "Insufficiant funds");
        require(airlines[msg.sender].isRegistered, "Airline not yet registered");
        require(!airlines[msg.sender].isVoter, "Airline is already a voter");

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


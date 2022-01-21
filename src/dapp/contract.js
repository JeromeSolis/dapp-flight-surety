import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.gas = 6721975;;
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            let self = this;
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            if (error) console.log(error);
            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
        .call({from:self.owner}, callback);
    }

    registerAirline(airline, from, callback) {
        let self = this;
        let payload = {
            airline: airline,
            from: from
        }
        self.flightSuretyApp.methods
            .registerAirline(payload.airline)
            .send({from:payload.from, gas:self.gas}, (error, result) => {
                callback(error, payload);
        });
    }

    getRegisteredStatus(airline, callback) {
        let self = this;
        let payload = {
            airline:airline
        }
        self.flightSuretyApp.methods
            .isRegisteredAirline(payload.airline)
            .call({from:self.owner}, callback);
    }

    fundAirline(airline, callback) {
        let self = this;
        let amount = self.web3.utils.toWei("10","ether");
        let payload = {
            airline:airline,
            payment:amount
        }
        self.flightSuretyApp.methods
            .fundAirline()
            .send({from:payload.airline, value:payload.payment, gas:self.gas}, callback);
    }

    getFundedStatus(airline, callback) {
        let self = this;
        let payload = {
            airline:airline
        }
        self.flightSuretyApp.methods
            .isFundedAirline(payload.airline)
            .call({from:self.owner}, callback);
    }

    registerFlight(airline, flight, timestamp, callback) {
        let self = this;
        let date = new Date(timestamp);
        let payload = {
            airline:airline,
            flight:flight,
            timestamp:Math.floor(date.getTime()/1000)
        }
        self.flightSuretyApp.methods
            .registerFlight(payload.flight, payload.timestamp)
            .send({from:airline, gas:self.gas}, (error, result) => {
                callback(error, payload);
            })
    }

    fetchFlightStatus(airline, flight, timestamp, callback) {
        let self = this;
        let date = new Date(timestamp);
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: Math.floor(date.getTime()/1000)
        } 

        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({from:self.owner, gas:self.gas}, (error, result) => {
                callback(error, payload);
        });
    }

    getFlightStatus(airline, flight, timestamp, callback) {
        let self = this;
        let date = new Date(timestamp);
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: Math.floor(date.getTime()/1000)
        } 
        
        self.flightSuretyApp.methods
            .getFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .call({from:self.owner}, callback);
    }

    buyInsurance(airline, flight, timestamp, passenger, value, callback) {
        let self = this;
        let amount = self.web3.utils.toWei(value, "ether");
        let date = new Date(timestamp);

        let payload = {
            airline:airline,
            flight:flight,
            timestamp:Math.floor(date.getTime()/1000),
            passenger: passenger,
            payment:amount
        };

        self.flightSuretyApp.methods
            .buyInsurance(payload.airline, payload.flight, payload.timestamp)
            .send({from:payload.passenger, value:payload.payment, gas:self.gas}, (error, result) => {
                callback(error, payload);
        })
    }

    withdrawCreditedAmount(passenger, value, callback) {
        let self = this;
        let amount = self.web3.utils.toWei(value, "ether");

        let payload = {
            passenger:passenger,
            amount:amount
        }

        self.flightSuretyApp.methods
            .withdrawCreditedAmount(payload.amount).send({from:payload.passenger, gas:self.gas}, (error, result) => {
                callback(error, payload);
        })
    }
}
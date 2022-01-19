import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http','ws')));
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
            // Register airlines


            // Register flights
            // flightTimestamp = new Date('2022-01-21 05:30:00');
            self.flightSuretyApp.methods.registerFlight({
                airline:accts[0],
                flight:'AC8449',
                timestamp:Math.floor((new Date('2022-01-21 05:30:00')).getTime()/1000)
            }).send({from:accts[0], gas:self.gas});

            self.flightSuretyApp.methods.registerFlight({
                airline:accts[0],
                flight:'AC481',
                timestamp:Math.floor((new Date('2022-01-21 06:00:00')).getTime()/1000)
            }).send({from:accts[0], gas:self.gas});

            self.flightSuretyApp.methods.registerFlight({
                airline:accts[0],
                flight:'AC485',
                timestamp:Math.floor((new Date('2022-01-21 06:30:00')).getTime()/1000)
            }).send({from:accts[0], gas:self.gas});

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

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
        });
    }

    registerAirline(airline, callback) {
        let self = this;
        let payload = {
            airline: airline
        }
        self.flightSuretyApp.methods
            .registerAirline(payload.airline)
            .send({from:self.owner}, (error, result) => {
                callback(error, payload);
        });
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
            .send({from:payload.airline, value:payload.payment, gas:self.gas}, (error, result) => {
                callback(error, payload);
        });
    }

    buyInsurance(airline, flight, timestamp, value, callback) {
        let self = this;
        let amount = self.web3.utils.toWei(value, "ether");

        let payload = {
            airline:airline,
            flight:flight,
            timestamp:timestamp,
            payment:amount
        };

        self.flightSuretyApp.methods
            .buyInsurance(payload.airline, payload.flight, payload.timestamp)
            .send({from:self.passengers[0], value:amount, gas:self.gas}, (error, result) => {
                callback(error, payload);
        })
    }

    withdrawCreditedAmount(value, callback) {
        let self = this;
        let amount = self.web3.utils.toWei(value, "ether");

        let payload = {
            amount:amount
        }

        self.flightSuretyApp.methods
            .withdrawCreditedAmount(payload.amount).send({from:self.passengers[0]}, (error, result) => {
                callback(error, payload);
        })
    }
}
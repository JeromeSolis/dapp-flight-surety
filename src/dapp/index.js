
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('register-airline').addEventListener('click', () => {
            let airline = DOM.elid('register-airline-address').value;
            let from = DOM.elid('register-airline-from-address').value;
            
            contract.registerAirline(airline, from, (error, result) => {
                console.log(error, result);
                display('Airlines', 'Register airlines', [{ label: 'Register Airline', error: error, value: result.airline}]);
            });
        })

        DOM.elid('registered-status').addEventListener('click', () => {
            let airline = DOM.elid('register-airline-address').value;

            contract.getRegisteredStatus(airline, (error, result) => {
                console.log(error, result);
                display('Flight', 'Get Status Code', [ { label: 'Registered Status', error: error, value:'Registered Status ' + result}]);
            })
        })

        DOM.elid('fund-airline').addEventListener('click', () => {
            let airline = DOM.elid('register-airline-address').value;

            contract.fundAirline(airline, (error, result) => {
                console.log(error, result);
                display('Airlines', 'Fund airlines', [{label: 'Fund Airline', error:error, value:result.airline + ' ' + result.payment}]);
            })
        })

        DOM.elid('funded-status').addEventListener('click', () => {
            let airline = DOM.elid('register-airline-address').value;

            contract.getFundedStatus(airline, (error, result) => {
                console.log(error, result);
                display('Flight', 'Get Status Code', [ { label: 'Funded Status', error: error, value:'Funded Status ' + result}]);
            })
        })

        DOM.elid('register-flight').addEventListener('click', () => {
            let airline = DOM.elid('flight-airline-address').value;
            let flight = DOM.elid('flight-id').value;
            let timestamp = DOM.elid('flight-timestamp').value;

            contract.registerFlight(airline, flight, timestamp, (error, result) => {
                console.log(error, result);
                display('Flight', 'Register flight', [{label: 'Register Flight', error:error, value:result.flight+ ' ' + result.timestamp}]);
            })
        })

        DOM.elid('submit-oracle').addEventListener('click', () => {
            let airline = DOM.elid('flight-airline-address').value;
            let flight = DOM.elid('flight-id').value;
            let timestamp = DOM.elid('flight-timestamp').value;

            // Write transaction
            contract.fetchFlightStatus(airline, flight, timestamp, (error, result) => {
                console.log(error, result);
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            })
        })

        DOM.elid('get-status-code').addEventListener('click', () => {
            let airline = DOM.elid('flight-airline-address').value;
            let flight = DOM.elid('flight-id').value;
            let timestamp = DOM.elid('flight-timestamp').value;

            contract.getFlightStatus(airline, flight, timestamp, (error, result) => {
                console.log(error, result);
                display('Flight', 'Get Status Code', [ { label: 'Flight Status Code', error: error, value:'Status code ' + result}]);
            })
        })

        DOM.elid('buy-insurance').addEventListener('click', () => {
            let passenger = DOM.elid('passenger').value;
            let amount = DOM.elid('insurance-amount').value;

            let airline = DOM.elid('flight-airline-address').value;
            let flight = DOM.elid('flight-id').value;
            let timestamp = DOM.elid('flight-timestamp').value;

            contract.buyInsurance(airline, flight, timestamp, passenger, amount, (error, result) => {
                console.log(error, result);
                display('Insurance', 'Buy Insurance', [{label: 'Buy Insurance', error:error, value:result.passenger+ ' ' + result.amount}]);
            })
        })

        DOM.elid('withdraw-credits').addEventListener('click', () => {
            let passenger = DOM.elid('passenger').value;
            let amount = DOM.elid('insurance-amount').value;

            contract.withdrawCreditedAmount(passenger, amount, (error, result) => {
                console.log(error, result);
                display('Credits', 'Withdraw Credits', [{label: 'Withdraw Credits', error:error, value:result.passenger + ' ' + result.amount}]);
            })
        })
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}








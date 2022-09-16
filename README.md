# Simple Car Rental Smart Contract

In this project, it is aimed to prepare a smart contract over the car rental scenario.

### Contract Flow

- Vehicle owners add their cars to the system.
- The renter requests a rental for the car he chooses. At this stage, the deposit must be paid.
- The renter confirms that he has received the car with the car delivery method. At this stage, he has to pay the rental fee.
- At the end of the process, the owner confirms that he has received the vehicle back. If the renter has not exceeded the delivery date, the deposit is forwarded to the lessor, and if it is exceeded, it is forwarded to the car owner.

### Hardhat commands

- npx hardhat help
- npx hardhat test
- npx hardhat node

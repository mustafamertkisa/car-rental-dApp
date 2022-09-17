// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @author Mustafa Mert Kisa
/// @title A simple car rental smart contract

contract carRental {
    struct Car {
        uint256 carId; // the id assigned to the car
        string model; // car model information
        uint256 dailyWages; // daily rental price of the car
        bool isAvailable; // availability of the car
        address owner; // owner of the car
    }

    struct Rent {
        uint256 rentId; // operation number
        uint256 carId; // id of the rented car
        uint256 rentalStartTime; // start date of operation
        uint256 dayToRent; // the number of days to be rented
        address hirer; // lessor's address
        uint256 deposit; // deposit fee
        bool checkDeposit;
        bool isComplete;
    }

    Car[] public cars;
    Rent[] public rents;

    /// ****** EXTERNAL FUNCTIONS *****

    /// @notice car owners can add this function to their car to the system
    /// @dev id set according to cars array and car availability initialized to true
    function addNewCar(string memory _model, uint256 _dailyWages) external {
        uint256 currentId = cars.length;
        Car memory carPosting = Car(
            currentId,
            _model,
            _dailyWages,
            true,
            msg.sender
        );
        cars.push(carPosting);
    }

    /// @notice with this function the lessor can deposit the deposit and start the rental process
    function rentalRequest(uint256 _carId, uint256 _dayToRent)
        external
        payable
    {
        uint256 calculatedDeposit = calculateDeposit(_carId);
        require(cars[_carId].isAvailable, "Car not available");
        require(msg.value >= calculatedDeposit, "Insufficient deposit");
        cars[_carId].isAvailable = false;
        uint256 currentId = rents.length;
        Rent memory rentDetail = Rent(
            currentId,
            _carId,
            block.timestamp,
            _dayToRent,
            msg.sender,
            msg.value,
            true,
            false
        );
        rents.push(rentDetail);
        (bool depositSent, bytes memory data) = address(this).call{
            value: msg.value
        }("");
    }

    /// @notice when the car is delivered, the car owner is paid, the function is only available to the hirer
    function deliveryCar(uint256 _carId, uint256 _rentId) external payable {
        uint256 calculatedPrice = calculatePrice(
            _carId,
            rents[_rentId].dayToRent
        );
        require(msg.sender == rents[_rentId].hirer, "Invalid hirer");
        require(msg.value >= calculatedPrice, "Insufficient price");
        require(_carId == rents[_rentId].carId, "Dont match car id");
        require(rents[_rentId].checkDeposit, "No deposit made");
        (bool sentPrice, bytes memory data) = cars[_carId].owner.call{
            value: msg.value
        }("");
    }

    /// @notice used when refunded in between, the deposit is refunded to the renter if the time has not expired, the function can only be used by the owner of the car
    function returnCar(uint256 _carId, uint256 _rentId) external payable {
        require(msg.sender == cars[_carId].owner, "Invalid owner");
        require(_carId == rents[_rentId].carId, "Dont match car id");
        require(!rents[_rentId].isComplete, "Process completed");
        cars[_carId].isAvailable = true;
        rents[_rentId].isComplete = true;
        uint256 dueDate = rents[_rentId].rentalStartTime +
            ((rents[_rentId].dayToRent * 24) * 3600);

        if (block.timestamp <= dueDate) {
            (bool returnDeposit, bytes memory data) = rents[_rentId].hirer.call{
                value: rents[_rentId].deposit
            }("");
        } else {
            (bool returnDeposit, bytes memory data) = cars[_carId].owner.call{
                value: rents[_rentId].deposit
            }("");
        }
    }

    /// ****** PUBLIC FUNCTIONS *****

    /// @notice calculates the price based on the number of days to be rented
    function calculatePrice(uint256 _carId, uint256 _dayToRent)
        public
        view
        returns (uint256)
    {
        return cars[_carId].dailyWages * _dayToRent;
    }

    /// @notice the deposit calculation was made by calculating three times the rental fee of the car
    function calculateDeposit(uint256 _carId) public view returns (uint256) {
        return cars[_carId].dailyWages * 3;
    }

    function getCarCount() public view returns (uint256) {
        return cars.length;
    }

    function getRentCount() public view returns (uint256) {
        return rents.length;
    }
}

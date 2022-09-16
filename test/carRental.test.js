const { expect } = require("chai");
const { ethers } = require("hardhat");
const Web3 = require("web3");

let alex, alice, bob, cedric;
let contractInstance;
describe("CarRental Test", function () {
  before(async function () {
    web3 = new Web3();
    [alex, alice, bob, cedric] = await ethers.getSigners();
    const ContractInstance = await ethers.getContractFactory("carRental");
    contractInstance = await ContractInstance.connect(alex).deploy();
  });

  describe("Deployment Test", function () {
    it("Should deploy the contracts", async function () {
      expect(contractInstance.address).to.not.be.undefined;
    });
  });

  describe("Contract Functions", function () {
    it("Alice add new car", async function () {
      const model = "Ford Mustang";
      const dailyWages = web3.utils.toWei("1");
      await contractInstance.connect(alice).addNewCar(model, dailyWages);

      expect(1).to.be.equal(await contractInstance.getCarCount());
    });

    it("Cedric submit rental request", async function () {
      const carId = 0;
      const dayToRent = 5;
      const deposit = await contractInstance.calculateDeposit(carId);
      const currentCedricBalance = Number(
        web3.utils.fromWei(
          String(await contractInstance.provider.getBalance(cedric.address))
        )
      );
      await contractInstance
        .connect(cedric)
        .rentalRequest(carId, dayToRent, { value: deposit });
      let carAvailable = await contractInstance.cars(carId);
      carAvailable = carAvailable.isAvailable;
      const newCedricBalance = Number(
        web3.utils.fromWei(
          String(await contractInstance.provider.getBalance(cedric.address))
        )
      );

      expect(1).to.be.equal(await contractInstance.getRentCount());
      expect(false).to.be.equal(carAvailable);
      expect(true).to.be.equal(newCedricBalance < currentCedricBalance);
    });

    it("Cedric delivery car", async function () {
      const carId = 0;
      const rentId = 0;
      let rentDayToRent = await contractInstance.rents(rentId);
      rentDayToRent = rentDayToRent.dayToRent;
      const price = await contractInstance.calculatePrice(carId, rentDayToRent);
      const currentCedricBalance = Number(
        web3.utils.fromWei(
          String(await contractInstance.provider.getBalance(cedric.address))
        )
      );
      const currentAliceBalance = Number(
        web3.utils.fromWei(
          String(await contractInstance.provider.getBalance(alice.address))
        )
      );

      await contractInstance
        .connect(cedric)
        .deliveryCar(carId, rentId, { value: price });
      let carAvailable = await contractInstance.cars(carId);
      carAvailable = carAvailable.isAvailable;
      const newCedricBalance = Number(
        web3.utils.fromWei(
          String(await contractInstance.provider.getBalance(cedric.address))
        )
      );
      const newAliceBalance = Number(
        web3.utils.fromWei(
          String(await contractInstance.provider.getBalance(alice.address))
        )
      );

      expect(true).to.be.equal(newCedricBalance < currentCedricBalance);
      expect(true).to.be.equal(newAliceBalance > currentAliceBalance);
    });

    it("Car returns to alice before end date", async function () {
      const carId = 0;
      const rentId = 0;
      let rentDayToRent = await contractInstance.rents(rentId);
      rentDayToRent = rentDayToRent.dayToRent;
      const currentCedricBalance = Number(
        web3.utils.fromWei(
          String(await contractInstance.provider.getBalance(cedric.address))
        )
      );

      await contractInstance.connect(alice).returnCar(carId, rentId);
      let carAvailable = await contractInstance.cars(carId);
      carAvailable = carAvailable.isAvailable;
      const newCedricBalance = Number(
        web3.utils.fromWei(
          String(await contractInstance.provider.getBalance(cedric.address))
        )
      );
      let carInfo = await contractInstance.cars(carId);
      let rentInfo = await contractInstance.rents(rentId);

      expect(true).to.be.equal(newCedricBalance > currentCedricBalance);
      expect(true).to.be.equal(carInfo.isAvailable);
      expect(true).to.be.equal(rentInfo.isComplete);
    });
  });
});

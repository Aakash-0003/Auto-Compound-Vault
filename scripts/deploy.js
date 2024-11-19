const { ethers } = require("hardhat");

async function main() {
    // Addresses of the required contracts
    const ISLAND_TOKEN = "0x63b0EdC427664D4330F72eEc890A86b3F98ce225";
    const OBERO = "0x7629668774f918c00Eb4b03AdF5C4e2E53d45f0b";
    const GAUGE = "0x996c24146cDF5756aFA42fa78447818A9a304851";
    const PLUGIN = "0x398A242f9F9452C1fF0308D4b4bf7ae6F6323868";
    const KODIAK_SWAP = "0x66E8F0Cf851cE9be42a2f133a8851Bc6b70B9EBd";
    const KODIAK_ROUTER = "0x4d41822c1804ffF5c038E4905cfd1044121e0E85";

    const HONEY = "0x0E4aaF1351de4c0264C5c7056Ef3777b41BD8e03";
    const NECT = "0xf5AFCF50006944d17226978e594D4D25f4f92B40"; // Replace with NECT address


    console.log("Deploying Vault...");

    // Get contract factory
    const Vault = await ethers.getContractFactory("Vault");

    // Deploy the contract
    const vault = await Vault.deploy(
        ISLAND_TOKEN,
        OBERO,
        GAUGE,
        PLUGIN,
        KODIAK_SWAP,
        KODIAK_ROUTER,
        ISLAND_TOKEN,
        HONEY,
        NECT
    );

    // Wait for the transaction to be mined
    //const vault = await ethers.getContractAt(abi, address);

    console.log("AutoCompoundingVault deployed to:", vault.target);
}

// Run the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

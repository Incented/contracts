const hre = require("hardhat");

async function main() {
    const ImplementationContractEcosystem = await hre.ethers.getContractFactory(
        "EcosystemContract"
    );

    const ImplementationContractProject = await hre.ethers.getContractFactory(
        "ProjectContract"
    );
    const ImplementationContractTask = await hre.ethers.getContractFactory(
        "TaskContract"
    );

    

    // deploy the implementation contract of Ecosystem, project and task
    const implementationContractEcosystem = await ImplementationContractEcosystem.deploy();
    await implementationContractEcosystem.deployed();
    console.log("Implementation contract ", implementationContractEcosystem.address);

    const implementationContractProject = await ImplementationContractProject.deploy();
    await implementationContractProject.deployed();
    console.log("Implementation contract ", implementationContractProject.address);

    const implementationContractTask = await ImplementationContractTask.deploy();
    await implementationContractTask.deployed();
    console.log("Implementation contract ", implementationContractTask.address);



    const MinimalProxyFactory = await hre.ethers.getContractFactory(
        "MPFEcosystem"
    );
    // deploy the minimal factory contract
    const minimalProxyFactory = await MinimalProxyFactory.deploy();
    await minimalProxyFactory.deployed();

    console.log("Minimal proxy factory contract ", minimalProxyFactory.address);

   

    // call the deploy clone function on the minimal factory contract and pass parameters
    const deployCloneContractEcosystem = await minimalProxyFactory.deployEcosystemClone(implementationContractEcosystem.address, "Arbitrum", "arbitrum", "tokenAddress");

    await deployCloneContractEcosystem.wait();



    // get deployed proxy address
    var ProxyAddress1 = await minimalProxyFactory.getEcosystems("arbitrum");


    console.log("Ecosystem 1 address is ", ProxyAddress1);


    // load the clone
    const proxy1 = await hre.ethers.getContractAt(
        "EcosystemContract",
        ProxyAddress1
    );

  

    console.log("Proxy 1 is initialized == ", await proxy1.isInitialized());

    // console.log("Proxy 1 name is  == ", await proxy1.name());


    // console.log("Proxy 1 symbol is  == ", await proxy1.symbol());


    // await proxy1.mintNFT();
    // console.log("Proxy 1 total supply is  == ", await proxy1.totalSupply());


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
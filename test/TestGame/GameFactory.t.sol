// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/Games/Game.sol";
import "../../src/Games/GameFactory.sol";
import "../../src/Tokens/interfaces/ICOwner.sol";
import "../../src/Tokens/COwner_ERC721.sol";


contract GameFactoryTest is Test {
    //Game public game;
    GameFactory public gameFactory;
    ICOwner nft_interface;
    COwner cowner_contract;

    address public creator = address(1);



    function setUp() public {
        gameFactory = new GameFactory();
        cowner_contract = new COwner();
        nft_interface = ICOwner(address(cowner_contract));
    }


    function test_FillPool() public {
        // creates pool
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 10, address(cowner_contract));
        address newGamePool = gameFactory.getContractAddress("1");

        // get pool to fill amount
        uint amountToFill = gameFactory.getPoolToFillAmount(newGamePool);
        console.log("get pool to fill amount: ", amountToFill);

        // fill out the pool
        gameFactory.fillPool(10*(10**18), newGamePool);

        // get pool to fill amount again to check if we filled the pool completly
        uint amountToFill_AfterTransfer = gameFactory.getPoolToFillAmount(newGamePool);
        console.log("To fill amount after transfer: ", amountToFill_AfterTransfer);
    }
    // function testFail_FillPool () public {

    // }



    function test_GetContractAddress() public {
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 10, address(cowner_contract));
        address newGamePool = gameFactory.getContractAddress("1");
        console.log(newGamePool);
    }
    function test_GetPoolAddressFromArray() public {
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 10, address(cowner_contract));
        console.log(gameFactory.getPoolAddressFromArray(0));
    }

    function test_GetPoolRewardMultiplierFromArray() public {
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 10, address(cowner_contract));
        console.log(gameFactory.getPoolRewardMultiplierFromArray(0));
    }

}

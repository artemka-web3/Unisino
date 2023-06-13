// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/Games/Game.sol";
import "../../src/Games/GameFactory.sol";
import "../../src/Games/interfaces/IGameFactory.sol";
import "../../src/Tokens/interfaces/ICOwner.sol";
import "../../src/Tokens/COwner_ERC721.sol";


contract GameTest is Test {
    // Game public game;
    GameFactory public gameFactory;
    IGameFactory public game_factory_interface;
    address public cowner_erc721 = address(1);
    ICOwner nft_interface;
    COwner cowner_contract;

    address public creator = address(2);
    address public player = 0x40A3Bb5933DFfF4b1978b0e6e1f582a292E55585;
    address public lp = address(3);

    uint256 public constant multiplier = 10**18;
    uint256 public constant shares_multiplier = 10**2;


    function setUp() public {
        gameFactory = new GameFactory();
        cowner_contract = new COwner();
        nft_interface = ICOwner(address(cowner_contract));
        game_factory_interface = IGameFactory(address(gameFactory));
    }

    //receive() external payable {}

    // @tested --okay
    function test_GenerateRandomNumber() public {
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 10, address(cowner_contract));
        address newGamePool = gameFactory.getContractAddress("1");

        uint256 param = Game(payable(newGamePool)).generateRandomNumber(0x40A3Bb5933DFfF4b1978b0e6e1f582a292E55585);
        console.log("RANDOM_NUMBER: ", param);
    }


    function test_Initialize() public {
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 10, address(cowner_contract));
        address newGamePool = gameFactory.getContractAddress("1");
        Game game = Game(payable(newGamePool));


        gameFactory.fillPool(10 * multiplier, newGamePool);
        assertEq(newGamePool.balance, 10 * multiplier);


        assertEq(game.getProviderEthAmount(0), 10 * multiplier);
        assertEq(game.getProviderSharesAmount(0), 10 * shares_multiplier * multiplier);
        assertEq(game.totalSharesSupply(), 10 * shares_multiplier * multiplier);
        assertEq(game.reward_multiplier(), 10);


        console.log("getProviderEthAmount: ", game.getProviderEthAmount(0));
        console.log("getProviderSharesAmount: ", game.getProviderSharesAmount(0));
        console.log("totalSharesSupply: ", game.totalSharesSupply());
        console.log("reward_multiplier: ", game.reward_multiplier());
    }

    // what if player guess the generated number
    function test_PlayWinCase() public {
        // create pool
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 2, address(cowner_contract));
        address newGamePool = gameFactory.getContractAddress("1");
        Game game = Game(payable(newGamePool));


        // fill out pool
        gameFactory.fillPool(10 * multiplier, newGamePool);
        console.log(newGamePool.balance);


        // play
        // 1) 100 - 5 = 95 - casino's balance
        // 2) 5 * 2 = 10
        // 3) 95 + 10 = 105 - player's balance
        hoax(player, 100 ether);
        game.play{value: 5 ether}(1);

        console.log("Player's Balance: ", player.balance);
        console.log("Casino's Balance: ", newGamePool.balance);
        console.log("getWinnerWinAmount: ", game.getWinnerWinAmount(0));
        console.log("getWinnerBetAmount: ", game.getWinnerBetAmount(0));
        console.log("Player's Reward left: ", game.getRewardAmount(player));

        assertEq(game.getWinnerWinAmount(0), 10 * multiplier);
        assertEq(game.getWinnerBetAmount(0), 5 * multiplier);

        game.take_reward(0x40A3Bb5933DFfF4b1978b0e6e1f582a292E55585);
        console.log("Player's Reward left: ", game.getRewardAmount(player));
        console.log("Player's Balance: ", player.balance);
        console.log("Casino's Balance: ", newGamePool.balance);       
        //assertEq(newGamePool.balance, 5 * multiplier);
        //assertEq(player.balance, 105 * multiplier);
    }
    // what if player doesn't guess the generated number
    function test_PlayLoseCase() public {
        // create pool
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 2, address(cowner_contract));
        address newGamePool = gameFactory.getContractAddress("1");
        Game game = Game(payable(newGamePool));


        // fill out pool
        gameFactory.fillPool(10 * multiplier, newGamePool);
        console.log(newGamePool.balance);

        hoax(player, 100 ether);
        game.play{value: 5 ether}(2);


        console.log("Lost Bets: ", game.lostBets());

        game.distributeBets();

        console.log("Lost Bets: ", game.lostBets());
        console.log("creator balance", creator.balance);
    }
    function test_PlayLoseCaseWithManyLPs() public {
        // create pool
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 2, address(cowner_contract));
        address newGamePool = gameFactory.getContractAddress("1");
        Game game = Game(payable(newGamePool));

        // fill out pool
        gameFactory.fillPool(10 * multiplier, newGamePool);
        console.log("Game balance after init: ", newGamePool.balance);
        console.log("Total Shares after init: ", game.totalSharesSupply());
        console.log("Creator Shares after init: ", game.getProviderSharesAmount(0));
        console.log("----------------------------------");



        // deposit testing
        hoax(lp, 100 ether);
        game.deposit{value: 20 ether}();
        console.log("Game balance after LP's deposit: ", newGamePool.balance);
        console.log("Total Shares after LP's deposit: ", game.totalSharesSupply());
        console.log("Creator Shares after LP's deposit: ", game.getProviderSharesAmount(0));
        console.log("LP's Shares after LP's deposit: ", game.getProviderSharesAmount(1));
        console.log("----------------------------------");


        hoax(player, 100 ether);
        game.play{value: 5 ether}(2);
        console.log("Game balance after player's lose: ", newGamePool.balance);
        console.log("Lost Bets: ", game.lostBets()); // 5e18
        console.log("Total Shares after player's lose: ", game.totalSharesSupply());
        console.log("Creator Shares after player's lose: ", game.getProviderSharesAmount(0));
        console.log("LP's Shares after player's lose: ", game.getProviderSharesAmount(1));
        console.log("----------------------------------");


        game.distributeBets();
        console.log("Game balance after distribution: ", newGamePool.balance);
        console.log("Lost Bets: ", game.lostBets()); // 5e18
        console.log("Total Shares after distribution: ", game.totalSharesSupply());
        console.log("Creator Shares after distribution: ", game.getProviderSharesAmount(0));
        console.log("LP's Shares after distribution: ", game.getProviderSharesAmount(1));
        console.log("Creator ETH after distribution: ", game.getProviderEthAmount(0));
        console.log("LP's ETH after distribution: ", game.getProviderEthAmount(1));
        console.log("----------------------------------");

        // console.log("Game Balance: ", newGamePool.balance);
        // console.log("Total shares: ", game.totalSharesSupply());
        // console.log("LP shares amount: ", game.getProviderSharesAmount(1));
        // console.log("Creator shares amount: ", game.getProviderSharesAmount(0));
        // console.log("LP ETH amount: ", game.getProviderEthAmount(1));
        // console.log("Creator ETH amount: ", game.getProviderEthAmount(0));
    }


    function test_Deposit() public {
        // create pool
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 2, address(cowner_contract));
        address newGamePool = gameFactory.getContractAddress("1");
        Game game = Game(payable(newGamePool));

        // fill out pool
        gameFactory.fillPool(10 * multiplier, newGamePool);
        console.log(newGamePool.balance);


        // deposit testing
        hoax(lp, 100 ether);
        game.deposit{value: 5 ether}();
        // LPs - creator, lp
        console.log("Game Balance: ", newGamePool.balance);
        console.log("Total shares: ", game.totalSharesSupply());
        console.log("LP shares amount: ", game.getProviderSharesAmount(1));
        console.log("Creator shares amount: ", game.getProviderSharesAmount(0));
        console.log("LP ETH amount: ", game.getProviderEthAmount(1));
        console.log("Creator ETH amount: ", game.getProviderEthAmount(0));
    }
    // function testFail_Deposit() public {

    // }


    function test_Withdraw() public {
        // create pool
        hoax(creator, 100 ether);
        gameFactory.createContract{value: 10 ether}("1", 2, address(cowner_contract));
        address newGamePool = gameFactory.getContractAddress("1");
        Game game = Game(payable(newGamePool));

        // fill out pool
        gameFactory.fillPool(10 * multiplier, newGamePool);
        console.log("newGamePool: ", newGamePool.balance);
        console.log("getProviderEthAmount: ", game.getProviderEthAmount(0));
        console.log("getProviderSharesAmount: ", game.getProviderSharesAmount(0));
        game.withdraw(5 ether, creator);
        console.log("------------------------");
        console.log("newGamePool: ", newGamePool.balance);
        console.log("getProviderEthAmount: ", game.getProviderEthAmount(0));
        console.log("getProviderSharesAmount: ", game.getProviderSharesAmount(0));



    }
    // function testFail_Withdraw() public {

    // }




}

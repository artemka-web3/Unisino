// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Tokens/interfaces/ICOwner.sol";
import "./interfaces/IGameFactory.sol";



contract Game {
    IGameFactory game_factory_interface;
    ICOwner cowner_interface;
    address public creator;
    uint256 public reward_multiplier;
    uint256 public constant SHARE_MULTIPLIER = 10**2;
    uint256 public totalSharesSupply;
    // address(this).balance

    struct Winner{
        address user;
        uint256 bet;
        uint256 win;
        uint256 timestamp;
    }
    struct LP{
        uint256 shares_amount;
        address provider;
        uint256 eth_amount;
    }

    LP [] public providers;
    Winner [] public history;
    //mapping(uint256 => Winner) public history;
    mapping (address => uint256) public rewards; // mapping so player can take reward from casino
    uint256 public lostBets;


    receive() external payable {}


    function initialize(uint256 _reward_multiplier, address _creator, address _cowner_erc721, uint256 depositAmount, address _game_factory) external returns(address){
        require(creator == address(0), "Contract already initialized");
        cowner_interface = ICOwner(_cowner_erc721);
        game_factory_interface = IGameFactory(_game_factory);
        reward_multiplier = _reward_multiplier;
        creator = _creator;
        uint256 sharesToCreate = depositAmount * SHARE_MULTIPLIER;
        totalSharesSupply += sharesToCreate;
        providers.push(LP(sharesToCreate, _creator, depositAmount));
        cowner_interface.safeMint(_creator);
        return address(this);
        //game_factory_interface.fillPool(depositAmount, address(this));
    }
    // after initiliaze call fillPool in frontend
    // depositAmount will be entered number by user
    // address will be taken from createContract

    function play(uint _guessFromUser) public payable {
        require(msg.value >= 0, "You didn't provide ETH. Bet ETH to play game!");
        require(address(this).balance >= msg.value * reward_multiplier, "Not enough funds to pay you reward! Play another time!");
        uint256 numberGenerated = generateRandomNumber(msg.sender);
        if(_guessFromUser == numberGenerated){
            won(msg.value, msg.sender);
            // uint256 win_amount = msg.value * reward_multiplier;
            // rewards[msg.sender] += win_amount;
            // // require(address(this).balance >= win_amount, "Not enough funds to pay reward! Sorry!");
            // //_player.transfer(win_amount);
            // history.push(Winner(msg.sender, msg.value, win_amount, block.timestamp));
        } else {
            lost(msg.value);
        } 
    }
    function won(uint256 bet_amount, address _player) public {
        uint256 win_amount = bet_amount * reward_multiplier;
        rewards[_player] += win_amount;
        // require(address(this).balance >= win_amount, "Not enough funds to pay reward! Sorry!");
        //_player.transfer(win_amount);
        history.push(Winner(_player, bet_amount, win_amount, block.timestamp));
    }
    // for winners
    function take_reward(address player) public {
        require(rewards[player] >= 0, "You don't have any reward!");
        require(address(this).balance >= rewards[player], "Not enough funds to pay reward! Sorry! Wait for your moment!");
        payable(player).transfer(rewards[player]);
        rewards[player] = 0;
    }
    // another name - distribute_users_bets(){}
    function lost(uint256 bet_amount) public {
        lostBets += bet_amount;
        // for(uint i=0; i<providers.length; i++) { 
        //     uint256 eth_to_transfer = (providers[i].shares_amount * bet_amount) / totalSharesSupply; 
        //     payable(providers[i].provider).transfer(eth_to_transfer);
        // }
    }
    function distributeBets() public {
        for(uint i=0; i<providers.length; i++) { 
            uint256 eth_to_transfer = (providers[i].shares_amount * lostBets) / totalSharesSupply;
            payable(providers[i].provider).transfer(eth_to_transfer);
            providers[i].eth_amount += eth_to_transfer;
            lostBets -= eth_to_transfer;
        }
        
    }


    function deposit() public payable {
        uint256 sharesToAdd = msg.value * SHARE_MULTIPLIER;
        totalSharesSupply += sharesToAdd;
        if(providers.length > 1){
            for(uint i=0; i < providers.length; i++){
                if(msg.sender == providers[i].provider){
                    providers[i].shares_amount += sharesToAdd;
                } else {
                    providers.push(LP(sharesToAdd, msg.sender, msg.value));
                }
            }
        } else{
            if(msg.sender == providers[0].provider){
                providers[0].shares_amount += sharesToAdd;
            } else {
                providers.push(LP(sharesToAdd, msg.sender, msg.value));
            }
        }
    }
    function withdraw(uint256 amount, address user) public {
        uint256 creator_balance = getProviderEthAmount(0);
        if (user == creator && amount == creator_balance){
            revert("Owner can't withdraw all!");
        }
        uint coincidence;
        for(uint i=0; i<providers.length;i++){
            if(providers[i].provider == user && providers[i].shares_amount >= 0){
                coincidence+=1;
                providers[i].shares_amount -= amount * 100;
                totalSharesSupply -= amount * 100;
                providers[i].eth_amount -= amount;
                payable(user).transfer(amount);
            }
        }
        assert(coincidence==1);
    }


    function generateRandomNumber(address generator) public view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty, generator))
        );
        return (randomNumber % 10) + 1;
    }



    function getProviderEthAmount(uint _index) public view returns(uint){
        require(_index >= 0 && _index <= providers.length, "This provider doesn't exist!");
        return providers[_index].eth_amount;
    }
    function getProviderSharesAmount(uint _index) public view returns(uint){
        require(_index >= 0 && _index <= providers.length, "This provider doesn't exist!");
        return providers[_index].shares_amount;
    }
    function getWinnerWinAmount(uint _index) public view returns(uint){
        require(_index >= 0 && _index <= history.length, "This winner doesn't exist!");
        return history[_index].win;
    }
    function getWinnerBetAmount(uint _index) public view returns(uint){
        require(_index >= 0 && _index <= history.length, "This winner doesn't exist!");
        return history[_index].bet;
    }
    function getWinnerAddress(uint _index) public view returns(address){
        require(_index >= 0 && _index <= history.length, "This winner doesn't exist!");
        return history[_index].user;
    }
    function getWinnerTimestamp(uint _index) public view returns(uint){
        require(_index >= 0 && _index <= history.length, "This winner doesn't exist!");
        return history[_index].timestamp;
    }
    function getRewardAmount(address player) public view returns(uint256){
        return rewards[player];
    }



}





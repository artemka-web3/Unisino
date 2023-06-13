// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Game} from "./Game.sol";

contract GameFactory {
    struct CasinoPool {
        address creator;
        address payable pool;
        uint reward_multiplier;
        address cowner_erc721;
    }
    CasinoPool [] public poolsCreated;
    mapping(address => uint256) poolsToFill; // sth like wallet to fill pool
    
    event ContractCreated(address indexed contractAddress, address indexed creator);

    function createContract(bytes32 salt, uint256 reward_multiplier, address _cowner_erc721) public payable {
        if(poolsCreated.length != 0){
            for (uint i=0; i<poolsCreated.length; i++){
                if(poolsCreated[i].reward_multiplier == reward_multiplier){
                    revert("The CasinoPool with such reward_multiplier already created!");
                } 
                else if (poolsCreated[i].creator == msg.sender) {
                    revert("You already have casino. In v1, you can only create one casino. Sorry!");
                } 
                else {
                    bytes memory bytecode = type(Game).creationCode;
                    address payable gamePoolAddress;
                    assembly {
                        gamePoolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
                        if iszero(extcodesize(gamePoolAddress)) {
                            revert(0, 0)
                        }
                    }
                    poolsToFill[gamePoolAddress] = msg.value;
                    Game(gamePoolAddress).initialize(reward_multiplier, msg.sender, _cowner_erc721, msg.value, address(this));
                    poolsCreated.push(CasinoPool(msg.sender, gamePoolAddress, reward_multiplier, _cowner_erc721));
                    //payable(gamePoolAddress).transfer(msg.value); // transfer deposited ETH from User
                    emit ContractCreated(gamePoolAddress, msg.sender);
                }
            }
        } 
        else {
            bytes memory bytecode = type(Game).creationCode;
            address payable gamePoolAddress;
            assembly {
                gamePoolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
                if iszero(extcodesize(gamePoolAddress)) {
                    revert(0, 0)
                }
            }
            poolsToFill[gamePoolAddress] = msg.value;
            Game(gamePoolAddress).initialize(reward_multiplier, msg.sender, _cowner_erc721, msg.value, address(this));
            poolsCreated.push(CasinoPool(msg.sender, gamePoolAddress, reward_multiplier, _cowner_erc721));
            // payable(gamePoolAddress).transfer(msg.value); // transfer deposited ETH from User
            emit ContractCreated(gamePoolAddress, msg.sender);  
        }     

    }

    // can work like deposit to pool function && add funds while initializing pool 
    function fillPool(uint256 _amount, address _poolAddress) public {
        require(_amount <= poolsToFill[_poolAddress] && _amount >= 0, "Can't feel pool with this amount!");
        poolsToFill[_poolAddress] -= _amount;
        payable(_poolAddress).transfer(_amount);
    } 

    function getContractAddress(bytes32 salt) public view returns (address) {
        bytes memory bytecode = type(Game).creationCode;
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(bytecode)
        )))));
    }

    function getPoolAddressFromArray(uint _poolIndex) public view returns(address){
        require(_poolIndex >= 0 && _poolIndex <= poolsCreated.length, "This pool doesn't exist!");
        return poolsCreated[_poolIndex].pool;
    }
    function getPoolRewardMultiplierFromArray(uint _poolIndex) public view returns(uint){
        require(_poolIndex >= 0 && _poolIndex <= poolsCreated.length, "This pool doesn't exist!");
        return poolsCreated[_poolIndex].reward_multiplier;
    }
    function getPoolOwnerFromArray(uint _poolIndex) public view returns(address){
        require(_poolIndex >= 0 && _poolIndex <= poolsCreated.length, "This pool doesn't exist!");
        return poolsCreated[_poolIndex].creator;
    }
    function getPoolToFillAmount(address _poolAddress) public view returns(uint){
        return poolsToFill[_poolAddress];
    }


}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameFactory {
    function fillPool(uint256 _amount, address _poolAddress) external;
}
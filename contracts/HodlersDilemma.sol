pragma solidity ^0.4.24;

contract HodlersDilemma {
  address public owner;

  struct Game {
    address player1;
    address player2;
    bytes32 player1Commitment;
    bytes32 player2Commitment;
    uint256 expiration;
    bool complete;
  }

  Game[] public games;

  mapping(address => uint256) playerToGame;

  constructor() public {
    owner = msg.sender;
  }

  function() public payable {}
}
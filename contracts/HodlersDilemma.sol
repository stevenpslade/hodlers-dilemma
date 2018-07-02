pragma solidity ^0.4.24;

contract HodlersDilemma {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function() public payable {}
}
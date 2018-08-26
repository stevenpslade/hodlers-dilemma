pragma solidity ^0.4.24;

contract HodlersDilemma {
  address public owner;
  uint256 public globalPotAmount;
  uint256 public minPlayerFee;
  uint256 public gameExpiration = 3 days;
  uint128 public gameFee = 300; // 3%

  struct Game {
    address player1;
    address player2;

    uint256 wager;
    uint256 expiration;

    bytes32 player1Commitment;
    bytes5 player2Choice;

    bool complete;
  }

  Game[] public games;

  mapping(address => uint256) playerToGame;

  uint256[] incompleteGames;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier hasPaid() {
    require(msg.value >= minPlayerFee);
    _;
  }

  constructor(uint256 _minPlayerFee) public payable {
    owner = msg.sender;
    globalPotAmount = msg.value;
    minPlayerFee = _minPlayerFee;
  }

  function startGame(bytes32 _commitment) public payable hasPaid returns (uint256) {
    // ensure the global pot amount has enough to payout the winner(s)
    require(globalPotAmount >= msg.value);

    Game memory _game = Game({
      player1: msg.sender,
      player1Commitment: _commitment,
      wager: msg.value,
      complete: false
    });

    uint256 newGameId = games.push(_game) - 1;
    playerToGame[msg.sender] = newGameId;
    incompleteGames.push(newGameId);

    globalPotAmount -= msg.value;

    // TODO: this will not return ID as tx won't be mined, need to have an event here, test this
    return newGameId;
  }

  function joinGame(bytes5 _choice) public payable {
    uint256 index = _getUnplannedGame(incompleteGames.length);
    uint256 gameId = incompleteGames[index];

    Game storage game = games[gameId];
    require (
      game.player1 != address(0) && 
      game.player1 != msg.sender && 
      game.player2 == address(0) && 
      msg.value == game.wager && 
      game.complete == false
    );

    game.player2 = msg.sender;
    game.player2Choice = _choice;
    game.expiration = now + gameExpiration;
  }

  function reveal(bytes5 _choice, uint256 _nonce) public {
    // ensure the choice is either split or steal
    require(_choice == 'split' || _choice == 'steal');

    uint256 _gameId = playerToGame[msg.sender];
    Game storage game = games[_gameId];

    require(
      game.player1 == msg.sender && 
      game.player2 != address(0) && 
      game.complete == false &&
      game.expiration > now
    );

    require(keccak256(_choice, nonce) == game.player1Commitment);
    game.complete = true;

    if (_choice == 'split' && game.player2Choice == 'split') {
      // send original wager + half the winnings to each player
      uint256 reward = (game.wager / 2) - _calcFee(game.wager);
      game.player1.transfer(game.wager + reward);
      game.player2.transfer(game.wager + reward);
    } else if (_choice == 'steal' && game.player2Choice == 'split') {
      // send player1 wager and all winnings
      game.player1.transfer( (game.wager * 2) - _calcFee(game.wager) );
    } else if (_choice == 'split' && game.player2Choice == 'steal') {
      // send player2 wager and all winnings
      game.player2.transfer( (game.wager * 2) - _calcFee(game.wager) );
    } else if (_choice == 'steal' && game.player2Choice == 'steal') {
      // steal-steal result puts wagers towards globalPotAmount
      globalPotAmount += game.wager * 2;
    }

    // deleting finished game from incompleteGames and filling gap left in array
    _deleteFromIncompleteGames(_gameId);
  }

  // TODO: claimTimeout function
  // TODO: cancel function
  function cancel() public {
    uint256 _gameId = playerToGame[msg.sender];
    Game storage game = games[_gameId];

    require(
      game.player1 == msg.sender && 
      game.player2 == address(0) && 
      game.complete == false
    );

    game.complete = true;
    _deleteFromIncompleteGames(_gameId);
    
    msg.sender.transfer(game.wager);
  }

  function _getUnplannedGame(uint256 _max) internal pure returns(uint256) {
    /*
    * Not adding one to result of modulo because we are passing the length
    * of the array which is already one greater than highest index
    */
    return uint256(keccak256(block.timestamp)) % _max;
  }

  function _deleteFromIncompleteGames(uint256 _gameId) internal {
    for (uint i = 0; i < incompleteGames.length-1; i++) {
      if (incompleteGames[i] == _gameId) {
        incompleteGames[i] = incompleteGames[incompleteGames.length-1];
        break;
      }
    }

    delete incompleteGames[incompleteGames.length-1];
    incompleteGames.length--;
  }

  function _calcFee(uint256 _reward) internal pure returns(uint256) {
    return _reward * gameFee / 10000;
  }

  function changeGlobalPotAmount(uint256 _newPotAmount) public onlyOwner {
    globalPotAmount = _newPotAmount;
  }

  function changeMinPlayerFee(uint256 _newPlayerFee) public onlyOwner {
    minPlayerFee = _newPlayerFee;
  }

  function changeGameExpiration(uint256 _newExpiration) public onlyOwner {
    gameExpiration = _newExpiration;
  }

  function changeGameFee(uint128 _newGameFee) public onlyOwner {
    gameFee = _newGameFee;
  }

  // TODO: maybe make pause functionalityepic

  function() public payable {}
}
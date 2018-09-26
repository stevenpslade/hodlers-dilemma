pragma solidity ^0.4.24;

contract HodlersDilemma {
  address public owner;
  uint256 public gameWager;
  uint256 public payoutBank = 0;
  uint256 public gameExpiration = 7 days;
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

  event StartGame(
    address indexed _player1,
    uint256 _gameId
  );

  event JoinGame(
    address indexed _player2,
    uint256 _gameId
  );

  event FinishGame(
    address indexed _player1,
    uint256 _gameId
  );

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier hasPaid() {
    require(msg.value == gameWager);
    _;
  }

  modifier splitOrSteal(bytes5 _choice) {
    require(_choice == 'split' || _choice == 'steal');
    _;
  }

  constructor(uint256 _gameWager) public payable {
    owner = msg.sender;
    gameWager = _gameWager;
  }

  function getGamesCount() public view returns(uint) {
    return games.length;
  }

  function getGame(uint256 index) public view returns(address, address, uint256, bool) {
      return (games[index].player1, games[index].player2, games[index].wager, games[index].complete);
  }

  function startGame(bytes32 _commitment) public payable hasPaid {
    // ensure contract balance will have enough to payout winnings
    require(address(this).balance - payoutBank >= msg.value);

    Game memory _game = Game({
      player1: msg.sender,
      player2 : address(0),
      player1Commitment: _commitment,
      player2Choice: 0,
      wager: msg.value,
      expiration: 0,
      complete: false
    });

    uint256 newGameId = games.push(_game) - 1;
    playerToGame[msg.sender] = newGameId;
    incompleteGames.push(newGameId);

    payoutBank += msg.value;

    emit StartGame(msg.sender, newGameId);
  }

  function joinGame(bytes5 _choice) public payable splitOrSteal(_choice) {
    uint256 index = _getUnplannedGame(incompleteGames.length);
    uint256 gameId = incompleteGames[index];

    Game storage game = games[gameId];
    require (
      game.player1 != address(0) && 
      game.player1 != msg.sender && 
      game.player2 == address(0) && 
      game.wager == msg.value && 
      game.complete == false
    );

    game.player2 = msg.sender;
    game.player2Choice = _choice;
    game.expiration = now + gameExpiration;

    emit JoinGame(msg.sender, gameId);
  }

  function reveal(bytes5 _choice, uint256 _nonce) public splitOrSteal(_choice) {
    uint256 _gameId = playerToGame[msg.sender];
    Game storage game = games[_gameId];

    require(
      game.player1 == msg.sender && 
      game.player2 != address(0) && 
      game.complete == false &&
      game.expiration > now
    );

    require(keccak256(abi.encodePacked(_choice, _nonce)) == game.player1Commitment);
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
    }
    // steal-steal contract keeps wagers

    payoutBank -= game.wager;

    // deleting finished game from incompleteGames and filling gap left in array
    _deleteFromIncompleteGames(_gameId);

    emit FinishGame(msg.sender, _gameId);
  }

  // claimTimeout can be called by player2 in the event that
  // player1 has not revealed their answer by the time the game
  // has expired. Player2 is rewarded based on the optimal outcome
  // for their answer.
  function claimTimeout() public {
    uint256 _gameId = playerToGame[msg.sender];
    Game storage game = games[_gameId];

    require(
      game.player2 == msg.sender && 
      now >= game.expiration && 
      game.complete == false
    );

    game.complete = true;
    payoutBank -= game.wager;
    _deleteFromIncompleteGames(_gameId);

    if (game.player2Choice == 'steal') {
      game.player2.transfer( (game.wager * 2) - _calcFee(game.wager) );
    } else if (game.player2Choice == 'split') {
      uint256 reward = (game.wager / 2) - _calcFee(game.wager);
      game.player2.transfer(game.wager + reward);
    }
  }

  function cancel() public {
    uint256 _gameId = playerToGame[msg.sender];
    Game storage game = games[_gameId];

    require(
      game.player1 == msg.sender && 
      game.player2 == address(0) && 
      game.complete == false
    );

    game.complete = true;
    payoutBank -= game.wager;
    _deleteFromIncompleteGames(_gameId);

    msg.sender.transfer(game.wager);
  }

  function _getUnplannedGame(uint256 _max) internal view returns(uint256) {
    /*
    * Not adding one to result of modulo because we are passing the length
    * of the array which is already one greater than highest index
    */
    return uint256(keccak256(abi.encodePacked(block.timestamp))) % _max;
  }

  function _deleteFromIncompleteGames(uint256 _gameId) internal {
    for (uint i = 0; i < incompleteGames.length; i++) {
      if (incompleteGames[i] == _gameId) {
        incompleteGames[i] = incompleteGames[incompleteGames.length-1];
        break;
      }
    }

    delete incompleteGames[incompleteGames.length-1];
    incompleteGames.length--;
  }

  function _calcFee(uint256 _reward) internal view returns(uint256) {
    return _reward * gameFee / 10000;
  }

  function changeGameWager(uint256 _newGameWager) public onlyOwner {
    gameWager = _newGameWager;
  }

  function changeGameExpiration(uint256 _newExpiration) public onlyOwner {
    gameExpiration = _newExpiration;
  }

  function changeGameFee(uint128 _newGameFee) public onlyOwner {
    gameFee = _newGameFee;
  }

  function withdrawBalance() external onlyOwner {
    if (address(this).balance > payoutBank) {
      owner.transfer(address(this).balance - payoutBank);
    }
  }

  function() public payable {}
}
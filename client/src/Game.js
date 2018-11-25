import React from 'react';

class Game extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      gameWagerDataKey: null,
      getIncompleteGamesDataKey: null,
      stackId: null,
      gameWager: null,
      choice: 'split',
      nonce: '',
      incompleteGames: null,
      games: null
    };

    const { drizzle, drizzleState } = this.props;
    const contract = drizzle.contracts.HodlersDilemma;

    contract.methods.gameWager().call().then((data) => {
      this.setState({ gameWager: data });
    });

    contract.methods.getIncompleteGames().call().then((data) => {
      this.setState({ incompleteGames: data });
    });
  }

  componentDidMount() {
    const { drizzle, drizzleState } = this.props;
    const contract = drizzle.contracts.HodlersDilemma;

    const gameWagerDataKey = contract.methods['gameWager'].cacheCall();
    const getIncompleteGamesDataKey = contract.methods['getIncompleteGames'].cacheCall();

    this.setState({ gameWagerDataKey, getIncompleteGamesDataKey });
  }

  startGame = (choice, nonce) => {
    const { drizzle, drizzleState } = this.props;
    const contract = drizzle.contracts.HodlersDilemma;

    const { HodlersDilemma } = drizzleState.contracts;
    const gameWager = HodlersDilemma.gameWager[this.state.gameWagerDataKey];

    const choiceNonceHex = drizzle.web3.utils.toHex(choice) + drizzle.web3.utils.toHex(nonce);
    const commitment = drizzle.web3.utils.keccak256(choiceNonceHex);

    const stackId = contract.methods['startGame'].cacheSend(commitment, {
      from: drizzleState.accounts[0],
      gas: 1000000,
      value: gameWager.value
    });

    this.setState({ stackId });
  }

  getTxStatus = () => {
    // get the transaction states from the drizzle state
    const { transactions, transactionStack } = this.props.drizzleState;

    // get the transaction hash using our saved `stackId`
    const txHash = transactionStack[this.state.stackId];

    // if transaction hash does not exist, don't display anything
    if (!txHash) return null;

    // otherwise, return the transaction status
    return `Transaction status: ${transactions[txHash].status}`;
  }

  displayGameWager = () => {
    const web3 = this.props.drizzle.web3;
    return <div>Game Wager: {this.state.gameWager && web3.utils.fromWei(this.state.gameWager, 'ether')} ETH</div>;
  }

  displayStartGameForm = () => {
    return (
      <form onSubmit={this.handleSubmit}>
        <label>
          Choice:
          <select name="choice" value={this.state.choice} onChange={this.handleChange}>
            <option value="split">Split</option>
            <option value="steal">Steal</option>
          </select>
        </label>
        <br />
        <label>
          Nonce:
          <input
            name="nonce"
            type="text"
            value={this.state.nonce}
            onChange={this.handleChange} />
        </label>
        <input type="submit" value="Submit" />
      </form>
    );
  }

  getGames = () => {
    const { HodlersDilemma } = this.props.drizzleState.contracts;
    const incompleteGamesRes = HodlersDilemma.getIncompleteGames[this.state.getIncompleteGamesDataKey];

    let games = [];
    if (incompleteGamesRes) {
      const contract = this.props.drizzle.contracts.HodlersDilemma;
      const incompleteGameIds = incompleteGamesRes.value;

      if (this.state.incompleteGames !== incompleteGameIds) {
        for (let i = 0; i < incompleteGameIds.length; i++) {
          let gameId = incompleteGameIds[i];

          contract.methods.getGame(gameId).call().then((data) => {
            games.push(data);
          });
        }

        this.setState({ games: games, incompleteGames: incompleteGameIds });
      }
    }
  }

  displayGames = () => {
    this.getGames();

    const web3 = this.props.drizzle.web3;
    let games = this.state.games;
    if (games && games.length > 0) {
      let gamesList = [];

      for (let i = 0; i < games.length; i++) {
        let game = games[i];
        gamesList.push(
          <div key={i}>
            <span>Player 1: {game[0]} </span>
            <span>Wager: {web3.utils.fromWei(game[2], 'ether')} ETH</span>
          </div>
        );
      }

      return gamesList;
    } else {
      return 'No games found.';
    }
  }

  handleChange = event => {
    const target = event.target;
    const value = target.value;
    const name = target.name;

    this.setState({
      [name]: value
    });
  }

  handleSubmit = event => {
    event.preventDefault();
    this.startGame(this.state.choice, this.state.nonce);
  }

  render() {
    return (
      <div>
        {this.displayGameWager()}
        {this.displayStartGameForm()}
        <div>{this.getTxStatus()}</div>
        <div>Games: {this.displayGames()}</div>
      </div>
    );
  };
}

export default Game;
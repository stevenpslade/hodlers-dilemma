import React from 'react';

class Game extends React.Component {
  state = { dataKey: null, stackId: null };

  componentDidMount() {
    const { drizzle, drizzleState } = this.props;
    const contract = drizzle.contracts.HodlersDilemma;

    const dataKey = contract.methods['gameWager'].cacheCall();

    this.setState({ dataKey });
  };

  startGame = (choice, nonce, wager) => {
    const { drizzle, drizzleState } = this.props;
    const contract = drizzle.contracts.HodlersDilemma;

    const commitment = drizzle.web3.utils.keccak256(choice, nonce);

    const stackId = contract.methods['startGame'].cacheSend(commitment, {
      from: drizzleState.accounts[0],
      value: drizzle.web3.utils.toWei(wager, 'ether')
    });

    this.setState({ stackId });
  };

  getTxStatus = () => {
    // get the transaction states from the drizzle state
    const { transactions, transactionStack } = this.props.drizzleState;

    // get the transaction hash using our saved `stackId`
    const txHash = transactionStack[this.state.stackId];

    // if transaction hash does not exist, don't display anything
    if (!txHash) return null;

    // otherwise, return the transaction status
    return `Transaction status: ${transactions[txHash].status}`;
  };

  render() {
    const { HodlersDilemma } = this.props.drizzleState.contracts;
    const web3 = this.props.drizzle.web3;

    const gameWager = HodlersDilemma.gameWager[this.state.dataKey];

    // TODO: add form for starting game with choice and nonce

    return <div>Game Wager: {gameWager && web3.utils.fromWei(gameWager.value, 'ether')}</div>;
  };
}

export default Game;
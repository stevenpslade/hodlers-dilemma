import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from './App';
import registerServiceWorker from './registerServiceWorker';
import { Drizzle, generateStore } from 'drizzle';
import HodlersDilemma from './contracts/HodlersDilemma.json';

const options = { contracts: [HodlersDilemma] };

const drizzleStore = generateStore(options);
const drizzle = new Drizzle(options, drizzleStore);

ReactDOM.render(<App />, document.getElementById('root'));
registerServiceWorker();

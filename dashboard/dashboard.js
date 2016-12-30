
import {
  serverInterface,
  factorioClient,
  factorioServer
} from "../src/main.js";
import React, {Component} from 'react';
import blessed from 'blessed';
import {render} from 'react-blessed';
import Logger from "../src/utils/log-stream.js";


class App extends Component {

  constructor (props) {
    super(props);
    this.onLog = this._onLog.bind(this);
    this.state = {
      logs: []
    }
  }

  _onLog (level, application, ...params) {
    let logs = this.state.logs.slice(0);
    logs.push("["+level+"]["+application.toUpperCase()+"] "+params.join(" "));
    this.setState({ logs: logs });
  }

  componentWillMount () {
    Logger.on("log", this.onLog);
  }

  componentWillUnmount () {
    Logger.removeListener("log", this.onLog);
  }

  render () {
    const logs = this.state.logs.join("\n");
    return (<box  top="top"
           left="left"
           label="ProjectIO Console"
           scrollable={true}
           width="50%"
           height="50%"
           border={{type: 'line'}}
           style={{border: {fg: 'blue'}}}>
        {logs}
    </box>);
  }
}



// Create a screen object.
var screen = blessed.screen({
  smartCSR: true
});

screen.title = 'Project IO Dashboard';



// Quit on Escape, q, or Control-C.
screen.key(['escape', 'q', 'C-c'], function(ch, key) {
  return process.exit(0);
});


const component = render(<App />, screen);

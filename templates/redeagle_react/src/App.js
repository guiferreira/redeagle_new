import logo from './logo.svg';
import elixir from './logo-elixir.png';
import './App.css';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>ReactLixer</h1>
        <div className="flex">
          <img src={logo} className="App-logo" alt="logo" />
          <img src={elixir} className="App-logo" alt="logo" />
        </div>
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        
      </header>
    </div>
  );
}

export default App;

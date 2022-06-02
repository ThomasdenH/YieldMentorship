import React from "react";
import "./App.css";
import { WagmiConfig, createClient } from "wagmi";
import { Profile } from "./components/Profile";

const client = createClient();

function App() {
  return (
    <div className="App">
      <WagmiConfig client={client}>
        <Profile />
      </WagmiConfig>
    </div>
  );
}

export default App;

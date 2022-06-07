import { createContext, useState } from "react";
import "./App.css";
import { ethers, Signer } from "ethers";
import { Provider } from "@wagmi/core";
import { Contracts } from "./components/Contracts";
import "./Button.css";

interface IProviderAndSigner {
  provider: Provider;
  signer: Signer;
}

export const ProviderAndSigner = createContext<IProviderAndSigner | undefined>(
  undefined
);

const App = () => {
  const [signer, setSigner] = useState<Signer | undefined>(undefined);

  if (window.ethereum === undefined)
    return (
      <div className="App">
        <p role='textbox'>No Web3 provider found...</p>
      </div>
    );

  // Load the provider
  const provider = new ethers.providers.Web3Provider(window.ethereum as any);

  // Load the signer
  const loadSigner = async () => {
    // First ask for permission
    await provider.send("eth_requestAccounts", []);
    const signer = await provider.getSigner();
    setSigner(signer);
  };

  if (signer === undefined) {
    return (
      <div className="App">
        <button
          className="button"
          onClick={() => {
            loadSigner();
          }}
        >
          Click to connect your wallet!
        </button>
      </div>
    );
  } else {
    const providerAndSigner: IProviderAndSigner = {
      provider,
      signer,
    };
    return (
      <div className="App">
        <ProviderAndSigner.Provider value={providerAndSigner}>
          <Contracts />
        </ProviderAndSigner.Provider>
      </div>
    );
  }
}

export default App;

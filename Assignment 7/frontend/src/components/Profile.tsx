import { useAccount, useConnect, useDisconnect } from "wagmi";
import { InjectedConnector } from "wagmi/connectors/injected";
import { Contracts } from "./Contracts";

export function Profile() {
  const { data } = useAccount();
  const { connect } = useConnect({
    connector: new InjectedConnector(),
  });
  const { disconnect } = useDisconnect();

  if (data) {
    return (
      <div>
        Connected to {data.address}
        <button onClick={() => disconnect()}>Disconnect</button>
        <Contracts />
      </div>
    );
  }
  return <button onClick={() => connect()}>Connect Wallet</button>;
}

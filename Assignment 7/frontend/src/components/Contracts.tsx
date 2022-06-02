import { createContext } from "react";
import { useProvider } from "wagmi";
import { Market as MarketInterface } from "../types/Market";
import { Market__factory } from "../types/factories/Market__factory";

const MARKET_ADDRESS = "string";

export const Market = createContext<MarketInterface | undefined>(undefined);

export function Contracts() {
  const provider = useProvider();

  // We have been connected, load the market contract
  const market = Market__factory.connect(MARKET_ADDRESS, provider);

  return <Market.Provider value={market}><p>Loaded Market!</p></Market.Provider>;
}

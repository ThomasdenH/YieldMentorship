import { createContext, useContext } from "react";
import { Market as MarketInterface } from "../types/Market";
import { Market__factory } from "../types/factories/Market__factory";
import { IERC20, IERC20__factory } from "../types";
import { ProviderAndSigner } from "../App";
import { Panel } from "./Panel";

export interface IContractsContext {
  market: MarketInterface;
  weth: IERC20;
  dai: IERC20;
}

const MARKET_ADDRESS = "0xf9fe9360a5849437dda072652c4da0f7ac73f8e3";
const WETH_ADDRESS = "0xd0A1E359811322d97991E03f863a0C30C2cF029C";
const DAI_ADDRESS = "0xe35c265ece9fdda7c99708dec45e67ddb7804193";

export const ContractsContext = createContext<IContractsContext | undefined>(undefined);

export function Contracts() {
  // Load provider and signer
  const providerAndSigner = useContext(ProviderAndSigner);
  if (providerAndSigner === undefined)
    throw new Error('Contracts cannot be instantiated without providerAndSigner!');
  const { signer } = providerAndSigner;

  // We have been connected, load the market contract
  const market = Market__factory.connect(MARKET_ADDRESS, signer);
  const weth = IERC20__factory.connect(WETH_ADDRESS, signer);
  const dai = IERC20__factory.connect(DAI_ADDRESS, signer);

  return (
    <ContractsContext.Provider value={{ market, weth, dai }}>
          <Panel/>
    </ContractsContext.Provider>
  );
}

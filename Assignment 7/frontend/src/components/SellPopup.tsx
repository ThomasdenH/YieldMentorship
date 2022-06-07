import { BigNumber } from "ethers";
import { useContext, useEffect, useState } from "react";
import { ProviderAndSigner } from "../App";
import { formatUnits } from "../util";
import { ContractsContext } from "./Contracts";
import "./SellPopup.css";

const GAS_ESTIMATE_FOR_SELL: number = 4_000_000;

export interface Props {
  weth: BigNumber;
  dai: BigNumber;
  direction: Direction;
  open: boolean;

  closed(): void;
}

enum ConfirmationStatus {
  Unknown,
  NotApproved,
  Approved,
}

export enum Direction {
  WethToDai,
  DaiToWeth,
}

export const SellPopup = ({ dai, weth, open, closed, direction }: Props) => {
  const providerAndSigner = useContext(ProviderAndSigner);
  const contracts = useContext(ContractsContext);
  if (contracts === undefined || providerAndSigner === undefined)
    throw new Error("Panel instantiated before contracts");

  const [confirmationStatus, setConfirmationStatus] =
    useState<ConfirmationStatus>(ConfirmationStatus.Unknown);

  const loadConfirmationStatus = async () => {
    const address = await providerAndSigner.signer.getAddress();
    if (direction === Direction.DaiToWeth) {
      const allowance = await contracts.dai.allowance(
        address,
        contracts.market.address
      );
      if (allowance.lt(dai)) {
        setConfirmationStatus(ConfirmationStatus.NotApproved);
      } else {
        setConfirmationStatus(ConfirmationStatus.Approved);
      }
    } else {
      const allowance = await contracts.weth.allowance(
        address,
        contracts.market.address
      );
      if (allowance.lt(weth)) {
        setConfirmationStatus(ConfirmationStatus.NotApproved);
      } else {
        setConfirmationStatus(ConfirmationStatus.Approved);
      }
    }
  };

  useEffect(() => {
    loadConfirmationStatus();
  });

  // Sell Weth / Dai
  const sellWeth = async () => {
    const tx = await contracts.market.sellX(weth, {
      gasLimit: GAS_ESTIMATE_FOR_SELL,
    });
    await tx.wait();
  };

  const sellDai = async () => {
    const tx = await contracts.market.sellY(dai, {
      gasLimit: GAS_ESTIMATE_FOR_SELL,
    });
    await tx.wait();
  };

  const sell = async () => {
    if (direction === Direction.DaiToWeth) {
      await sellDai();
    } else {
      await sellWeth();
    }
    closed();
  };

  const approve = async () => {
    if (direction === Direction.DaiToWeth) {
      const tx = await contracts.dai.approve(contracts.market.address, dai);
      await tx;
    } else {
      const tx = await contracts.weth.approve(contracts.market.address, weth);
      await tx;
    }
    await loadConfirmationStatus();
  };

  if (!open) return <></>;

  return (
    <div className="sell-popup">
      <p>
        {direction === Direction.WethToDai
          ? `Selling ${formatUnits(weth, {
              showDecimals: 6,
            })} WETH for ${formatUnits(dai, { showDecimals: 2 })} DAI...`
          : `Selling ${formatUnits(dai, {
              showDecimals: 2,
            })} DAI for ${formatUnits(weth, { showDecimals: 6 })} WETH...`}
      </p>
      <button
        className="button"
        disabled={confirmationStatus !== ConfirmationStatus.NotApproved}
        onClick={() => {
          approve();
        }}
      >
        Approve
      </button>
      <button
        className="button"
        disabled={confirmationStatus !== ConfirmationStatus.Approved}
        onClick={() => {
          sell();
        }}
      >
        Sell!
      </button>
      <button
        className="close"
        onClick={() => {
          closed();
        }}
      >
        X
      </button>
    </div>
  );
}

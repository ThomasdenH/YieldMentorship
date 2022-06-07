import { BigNumber } from "ethers";
import { useContext, useState } from "react";
import { ProviderAndSigner } from "../App";
import { formatUnits } from "../util";
import { AmountDisplay } from "./AmountDisplay";
import { ContractsContext } from "./Contracts";
import "./Panel.css";
import { Direction, SellPopup } from "./SellPopup";

interface IBalances {
  balanceWeth: BigNumber;
  balanceDai: BigNumber;
  marketBalanceWeth: BigNumber;
  marketBalanceDai: BigNumber;
}

export const Panel = () => {
  const providerAndSigner = useContext(ProviderAndSigner);
  const contracts = useContext(ContractsContext);
  if (contracts === undefined || providerAndSigner === undefined)
    throw new Error("Panel instantiated before contracts");

  const [balances, setBalances] = useState<IBalances | undefined>();
  (async () => {
    const address = await providerAndSigner.signer.getAddress();
    const marketAddress = contracts.market.address;
    // TODO: Perhaps in parallel:
    const balanceWeth = await contracts.weth.balanceOf(address);
    const balanceDai = await contracts.dai.balanceOf(address);
    const marketBalanceWeth = await contracts.weth.balanceOf(marketAddress);
    const marketBalanceDai = await contracts.dai.balanceOf(marketAddress);
    setBalances({
      balanceWeth,
      balanceDai,
      marketBalanceWeth,
      marketBalanceDai,
    });
  })();

  // The current change in weth in pixels. I.e.: The ratio between this number
  //    and the height is the same as that between the change in Weth and the
  //    total balance.
  const [pixelChanges, setPixelChange] = useState<
    [number, number] | undefined
  >();

  const [sellPopupOpen, setSellPopupOpen] = useState<boolean>(false);
  const [transactionDirection, setTransactionDirection] = useState<Direction>(
    Direction.DaiToWeth
  );
  const [weth, setWeth] = useState<BigNumber>(BigNumber.from(0));
  const [dai, setDai] = useState<BigNumber>(BigNumber.from(0));

  if (balances === undefined) return <></>;

  /**
   * Get the current marginal value of Weth in terms of Dai.
   */
  const daiValueOfWeth = (weth: BigNumber) =>
    weth.mul(balances.marketBalanceDai).div(balances.marketBalanceWeth);

  /**
   * Compute the correct heights for the current balances of weth and dai, in
   * pixels.
   * @returns An array [wethHeight, daiHeight]
   */
  const computeHeights = (): [number, number] => {
    const maxHeight = 300;
    const valueWeth = daiValueOfWeth(balances.balanceWeth);

    // Assign maxHeight to maxValue.
    if (balances.balanceDai.gt(valueWeth)) {
      return [
        valueWeth.mul(maxHeight).div(balances.balanceDai).toNumber(),
        maxHeight,
      ];
    } else {
      return [
        maxHeight,
        balances.balanceDai.mul(maxHeight).div(valueWeth).toNumber(),
      ];
    }
  };

  /**
   * Preview how much Dai you would obtain when selling weth
   */
  const previewSellWeth = (weth: BigNumber): BigNumber =>
    // x0 * y0 = (x0 + x) * (y0 - y)
    // x0 * y0 / (x0 + x) - y0 = - y
    // y = y0 - (x0 * y0) / (x0 + x)
    // y = (y0 * x) / (x0 + x)
    balances.marketBalanceDai
      .mul(weth)
      .div(balances.marketBalanceWeth.add(weth));

  /**
   * Preview how much Weth you would obtain for selling Dai.
   */
  const previewSellDai = (dai: BigNumber) =>
    balances.marketBalanceWeth.mul(dai).div(balances.marketBalanceDai.add(dai));

  // Compute the heights of the full balances.
  const [heightWeth, heightDai] = computeHeights();

  /**
   * Convert how much pixels change corresponds to the change in Weth.
   */
  const convertWethChangeToWethPixels = (weth: BigNumber) =>
    weth.mul(heightWeth).div(balances.balanceWeth);

  /**
   * Convert how much Weth corresponds to the given change in pixels.
   */
  const convertWethChangePixelsToWeth = (pixels: number): BigNumber =>
    balances.balanceWeth.mul(Math.round(Math.abs(pixels))).div(heightWeth);

  /**
   * Convert a change in Dai to the corresponding amount of pixels.
   */
  const convertDaiToPixelsDai = (dai: BigNumber) =>
    dai.mul(heightDai).div(balances.balanceDai);

  /**
   * Convert a Dai pixel change to the corresponding amount of Dai.
   */
  const convertDaiPixelsToDai = (daiPixels: number): BigNumber =>
    balances.balanceDai.mul(Math.round(Math.abs(daiPixels))).div(heightDai);

  /**
   * Convert a change in weth pixels to a change in dai pixels.
   */
  const convertPixelsWethToPixelsDai = (pixels: number): number => {
    pixels = Math.max(pixels, 0);
    const realWeth = convertWethChangePixelsToWeth(pixels);
    const realDai = previewSellWeth(realWeth);
    const pixelsDai = convertDaiToPixelsDai(realDai);
    return pixelsDai.toNumber();
  };

  /**
   * Convert a change in Dai pixels to a change in Weth pixels.
   */
  const convertPixelsDaiToPixelsWeth = (pixelsChange: number) => {
    pixelsChange = Math.max(pixelsChange, 0);
    const realDai = convertDaiPixelsToDai(pixelsChange);
    const realWeth = previewSellDai(realDai);
    const pixelsWeth = convertWethChangeToWethPixels(realWeth);
    return pixelsWeth.toNumber();
  };

  const sellWeth = () => {
    if (pixelChanges === undefined) return;
    setWeth(convertWethChangePixelsToWeth(pixelChanges[0]));
    setDai(convertDaiPixelsToDai(pixelChanges[1]));
    setTransactionDirection(Direction.WethToDai);
    setSellPopupOpen(true);
  };

  const sellDai = () => {
    if (pixelChanges === undefined) return;
    setWeth(convertWethChangePixelsToWeth(pixelChanges[0]));
    setDai(convertDaiPixelsToDai(pixelChanges[1]));
    setTransactionDirection(Direction.DaiToWeth);
    setSellPopupOpen(true);
  };

  return (
    <div className="panel">
      <div className="amount-column">
        <AmountDisplay
          height={heightWeth}
          change={pixelChanges === undefined ? undefined : pixelChanges[0]}
          onMouseOut={() => {
            setPixelChange(undefined);
          }}
          onMouseMove={(wethPixelChange) => {
            const daiPixelChange =
              convertPixelsWethToPixelsDai(wethPixelChange);
            setPixelChange([-wethPixelChange, -daiPixelChange]);
          }}
          onClick={() => {
            sellWeth();
          }}
        />
        <p className="amountText">
          {formatUnits(balances.balanceWeth, { showDecimals: 6 })} WETH (
          {formatUnits(daiValueOfWeth(balances.balanceWeth), {
            showDecimals: 2,
          })}{" "}
          DAI)
        </p>
      </div>
      <div className="amount-column">
        <AmountDisplay
          height={heightDai}
          change={pixelChanges === undefined ? undefined : pixelChanges[1]}
          onMouseOut={() => {
            setPixelChange(undefined);
          }}
          onMouseMove={(daiPixelChange) => {
            const wethPixelChange =
              convertPixelsDaiToPixelsWeth(daiPixelChange);
            setPixelChange([wethPixelChange, daiPixelChange]);
          }}
          inverted={true}
          onClick={() => {
            sellDai();
          }}
        />
        <p className="amountText">
          {formatUnits(balances.balanceDai, { showDecimals: 2 })} DAI
        </p>
      </div>
      <SellPopup
        weth={weth}
        dai={dai}
        open={sellPopupOpen}
        closed={() => setSellPopupOpen(false)}
        direction={transactionDirection}
      />
    </div>
  );
}

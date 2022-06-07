import { BigNumber } from "ethers"

export const formatUnits = (dai: BigNumber, { decimals, showDecimals }: { decimals?: number; showDecimals?: number }): string => {
    if (decimals === undefined)
        decimals = 18;
    if (showDecimals === undefined)
        showDecimals = decimals;

    if (showDecimals > decimals)
        throw new Error('Cannot show more decimals than are available');

    const s = dai.toString();

    let whole = '0';
    if (s.length > decimals)
        whole = s.slice(0, s.length - decimals);

    if (showDecimals === 0)
        return whole;

    const frac = s.slice(s.length - decimals, s.length - decimals + showDecimals);
    return `${whole}.${frac}`;
};

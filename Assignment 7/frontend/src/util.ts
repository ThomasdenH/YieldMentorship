import { BigNumber } from "ethers"

export const formatUnits = (dai: BigNumber, { decimals, showDecimals }: { decimals?: number; showDecimals?: number }): string => {
    if (decimals === undefined)
        decimals = 18;
    if (showDecimals === undefined)
        showDecimals = decimals;
    const s = dai.toString();
    const whole = s.slice(0, s.length - decimals);
    const frac = s.slice(s.length - decimals, s.length - decimals + showDecimals);
    return `${whole}.${frac}`;
};

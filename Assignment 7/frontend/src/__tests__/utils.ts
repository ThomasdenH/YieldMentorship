import { BigNumber } from "ethers";
import { formatUnits } from "../util";

it("formats ETH correctly by default", () => {
  expect(
    formatUnits(BigNumber.from('456789000000000000000'), {})
  ).toEqual("456.789000000000000000");
  expect(
    formatUnits(BigNumber.from('456789012345678901234'), {})
  ).toEqual("456.789012345678901234");
});

it("formats whole number correctly", () => {
  expect(
    formatUnits(BigNumber.from(1000), { decimals: 3, showDecimals: 0 })
  ).toEqual("1");
  expect(
    formatUnits(BigNumber.from(1000), { decimals: 3, showDecimals: 1 })
  ).toEqual("1.0");
});

it('formats numbers without a whole part including a leading 0', () => {
    expect(
        formatUnits(BigNumber.from(100), {decimals: 3, showDecimals: 3 })
    ).toEqual('0.100');
});

it('shows `showDecimal` decimals (rounding down)', () => {
    expect(formatUnits(BigNumber.from('123450000'), { decimals: 6, showDecimals: 2})).toEqual('123.45');
    expect(formatUnits(BigNumber.from('123456789'), { decimals: 6, showDecimals: 2})).toEqual('123.45');
});

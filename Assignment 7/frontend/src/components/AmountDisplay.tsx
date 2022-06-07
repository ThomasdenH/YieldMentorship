import "./AmountDisplay.css";

interface Props {
  height: number;
  change: number | undefined;
  onMouseMove(y: number): void;
  onMouseOut(): void;
  onClick(): void;
  inverted?: boolean;
}

/**
 * A visual display of an amount. The height of the bar indicates the value in DAI, not the natural
 * units of the bar.
 */
export const AmountDisplay = ({
  height,
  onMouseMove,
  onMouseOut,
  change,
  inverted,
  onClick,
}: Props): JSX.Element => {
  let changeElement = <></>;
  if (change !== undefined) {
    if (inverted === true) change = -change;
    if (change < 0) {
      changeElement = (
        <div
          className={"sub-amount"}
          style={{
            height: `${-change}px`,
          }}
        ></div>
      );
    } else {
      changeElement = (
        <div
          className={"add-amount"}
          style={{
            height: `${change}px`,
            top: `${-change - 2}px`,
            left: "-1px",
          }}
        ></div>
      );
    }
  }

  return (
    <div
      style={{
        height: `${height}px`,
      }}
      className="visual-amount"
      onMouseMove={(e) => {
        onMouseMove(e.clientY - e.currentTarget.getBoundingClientRect().y);
      }}
      onMouseOut={() => {
        onMouseOut();
      }}
      onClick={() => {
        onClick();
      }}
    >
      {changeElement}
    </div>
  );
}

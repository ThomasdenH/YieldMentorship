import { render, screen } from "@testing-library/react";
import App from "../App";

it("shows a connect button", () => {
  render(<App />);
  expect(screen.getByRole("textbox")).toHaveTextContent("No Web3 provider found...");
});

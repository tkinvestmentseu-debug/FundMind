/* RNTL smoke test dla PremiumAiBanner (ASCII-only) */
import React from "react";
import { render } from "@testing-library/react-native";
jest.useFakeTimers();
import PremiumAiBanner from "../app/components/PremiumAiBanner";

test("renders PremiumAiBanner without crashing", () => {
  const screen = render(<PremiumAiBanner disableAnimation />);
  expect(screen.toJSON()).toBeTruthy();
});

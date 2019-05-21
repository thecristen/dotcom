import React from "react";
import renderer from "react-test-renderer";
import { createReactRoot } from "../../app/helpers/testUtils";
import Fares from "../components/Fares";

it("it doesn't render if there are no fares", () => {
  createReactRoot();
  const tree = renderer.create(<Fares fareLink="/fares" fares={[]} />).toJSON();
  expect(tree).toBeNull();
});

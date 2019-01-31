import React from "react";
import renderer from "react-test-renderer";
import Direction from "../components/Direction";
import createReactRoot from "./helpers/testUtils";
import tnmData from "./tnmData.json";
import { Route, Stop, TNMDirection } from "../components/__tnm";

it("it renders", () => {
  const route: Route = tnmData[0] as Route;
  const stop: Stop = route.stops[0];
  const direction: TNMDirection = stop.directions[0];

  createReactRoot();
  const tree = renderer
    .create(<Direction direction={direction} route={route} stopId={stop.id} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

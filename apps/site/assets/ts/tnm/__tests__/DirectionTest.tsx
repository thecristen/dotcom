import React from "react";
import renderer from "react-test-renderer";
import Direction from "../components/Direction";
import createReactRoot from "./helpers/testUtils";
import tnmData from "./tnmData.json";
import { Route, Stop, TNMDirection } from "../components/__tnm";

it("it renders", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0] as Route;
  const stop: Stop = route.stops[0];
  const direction: TNMDirection = stop.directions[0];

  createReactRoot();
  const tree = renderer
    .create(<Direction direction={direction} route={route} stopId={stop.id} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("returns null if direction has no schedules", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0] as Route;
  const stop: Stop = route.stops[0];
  const direction: TNMDirection = stop.directions[0];

  direction.headsigns = [];

  createReactRoot();
  const tree = renderer
    .create(<Direction direction={direction} route={route} stopId={stop.id} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

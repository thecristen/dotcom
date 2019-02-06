import React from "react";
import renderer from "react-test-renderer";
import StopCard from "../components/StopCard";
import { createReactRoot, createMarkers } from "./helpers/testUtils";
import { Route, Stop } from "../components/__tnm";
import tnmData from "./tnmData.json";

const markers = createMarkers();

it("it renders a stop card", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0] as Route;
  const stop: Stop = route.stops[0];

  createReactRoot();
  const tree = renderer
    .create(<StopCard stop={stop} route={route} markers={markers} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("returns null if stop has no schedules", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0];
  const stop: Stop = route.stops[0];

  expect(stop.directions.length).toBe(1);
  stop.directions[0].headsigns = [];

  const tree = renderer
    .create(<StopCard stop={stop} route={route} markers={markers} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

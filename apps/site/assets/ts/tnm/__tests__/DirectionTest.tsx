import React from "react";
import renderer from "react-test-renderer";
import Direction from "../components/Direction";
import { createReactRoot } from "./helpers/testUtils";
import tnmData from "./tnmData.json";
import { Route, Stop, TNMDirection } from "../components/__tnm";

it("it renders", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data.find((route: Route) =>
    route.stops.some((stop: Stop) =>
      stop.directions.some(
        (direction: TNMDirection) => direction.headsigns.length > 1
      )
    )
  );
  const stop: Stop = route.stops[0];
  const direction: TNMDirection = stop.directions[0];

  expect(route).not.toBeUndefined();

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

it("it does not display the route direction for commuter rail", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[data.length - 1] as Route;
  const stop: Stop = route.stops[0];
  const direction: TNMDirection = stop.directions[0];

  expect(route.type).toBe(2);

  createReactRoot();
  const tree = renderer
    .create(<Direction direction={direction} route={route} stopId={stop.id} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it does not display the direction destination when there is only one headsign", () => {
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

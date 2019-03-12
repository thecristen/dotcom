import React from "react";
import renderer from "react-test-renderer";
import Direction from "../components/Direction";
import { createReactRoot } from "./helpers/testUtils";
import {
  TNMDirection,
  TNMHeadsign,
  TNMRoute,
  TNMTime
} from "../components/__tnm";

/* eslint-disable typescript/camelcase */
const time: TNMTime = {
  scheduled_time: ["4:30", " ", "PM"],
  prediction: null,
  delay: 0
};

const headsign: TNMHeadsign = {
  name: "Headsign",
  times: [time],
  train_number: null
};

const direction: TNMDirection = {
  direction_id: 0,
  headsigns: [headsign]
};

const route: TNMRoute = {
  alert_count: 0,
  direction_destinations: ["Outbound Destination", "Inbound Destination"],
  direction_names: ["Outbound", "Inbound"],
  id: "route-id",
  name: "Route Name",
  header: "Route Header",
  long_name: "Route Long Name",
  description: "Route Description",
  stops: [],
  type: 1
};

it("it renders", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <Direction
        direction={{
          ...direction,
          headsigns: [1, 2].map(i => ({ ...headsign, name: `Headsign ${i}` }))
        }}
        route={route}
        stopId="stop-id"
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("returns null if direction has no schedules", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <Direction
        direction={{ ...direction, headsigns: [] }}
        route={route}
        stopId="stop-id"
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it does not display the route direction for commuter rail", () => {
  createReactRoot();
  const headsigns = [1, 2].map(i => ({
    ...headsign,
    name: `Headsign ${i}`,
    train_number: `59${i}`
  }));
  const tree = renderer
    .create(
      <Direction
        direction={{ ...direction, headsigns }}
        route={{ ...route, type: 2 }}
        stopId="stop-id"
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it does not display the direction destination when there is only one headsign", () => {
  createReactRoot();
  const tree = renderer
    .create(<Direction direction={direction} route={route} stopId="stop-id" />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

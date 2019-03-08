import React from "react";
import renderer from "react-test-renderer";
import RouteCard, {
  isSilverLine,
  routeBgColor,
  busClass
} from "../components/RouteCard";
import { createReactRoot } from "./helpers/testUtils";
import {
  Route,
  Stop,
  TNMDirection,
  TNMHeadsign,
  TNMTime
} from "../components/__tnm";

/* eslint-disable typescript/camelcase */

const time: TNMTime = {
  scheduled_time: ["4:30", " ", "PM"],
  prediction: null
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

const stop: Stop = {
  accessibility: ["wheelchair"],
  address: "123 Main St., Boston MA",
  closed_stop_info: null,
  "has_charlie_card_vendor?": false,
  "has_fare_machine?": false,
  id: "stop-id",
  "is_child?": false,
  latitude: 41.0,
  longitude: -71.0,
  name: "Stop Name",
  note: null,
  parking_lots: [],
  "station?": true,
  distance: "238 ft",
  directions: [direction],
  href: "/stops/stop-id"
};

const route: Route = {
  alert_count: 1,
  direction_destinations: ["Outbound Destination", "Inbound Destination"],
  direction_names: ["Outbound", "Inbound"],
  id: "route-id",
  name: "Route Name",
  header: "Route Header",
  long_name: "Route Long Name",
  description: "Route Description",
  stops: [stop],
  type: 3
};

it("it renders a stop card", () => {
  createReactRoot();
  const tree = renderer
    .create(<RouteCard route={route} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("returns null if route has no schedules", () => {
  const stopWithoutSchedules: Stop = { ...stop, directions: [] };
  const routeWithoutSchedules: Route = {
    ...route,
    stops: [stopWithoutSchedules]
  };
  createReactRoot();
  const tree = renderer
    .create(<RouteCard route={routeWithoutSchedules} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it renders a stop card for the silver line", () => {
  createReactRoot();
  const sl: Route = { ...route, id: "751" };
  const tree = renderer
    .create(<RouteCard route={sl} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

describe("isSilverLine", () => {
  it("identifies silver line routes", () => {
    ["741", "742", "743", "746", "749", "751"].forEach(id => {
      const sl: Route = { ...route, id };
      expect(isSilverLine(sl)).toBe(true);
    });
  });
});

describe("routeBgColor", () => {
  it("determines the background color by route", () => {
    const cr: Route = { ...route, type: 2 };
    expect(routeBgColor(cr)).toBe("commuter-rail");

    const ferry: Route = { ...route, type: 4 };
    expect(routeBgColor(ferry)).toBe("ferry");

    ["Red", "Orange", "Blue"].forEach(id => {
      const subway: Route = { ...route, type: 1, id };
      expect(routeBgColor(subway)).toBe(`${id.toLowerCase()}-line`);
    });

    const greenLine: Route = {
      ...route,
      type: 0,
      id: "Green-B"
    };
    expect(routeBgColor(greenLine)).toBe("green-line");

    const bus: Route = { ...route, type: 3, id: "1" };
    expect(routeBgColor(bus)).toBe("bus");

    const fake: Route = { ...route, type: 0, id: "fakeID" };
    expect(routeBgColor(fake)).toBe("unknown");
  });
});

describe("busClass", () => {
  it("determines a route is a bus route", () => {
    const bus: Route = { ...route, type: 3, id: "1" };
    expect(busClass(bus)).toBe("bus-route-sign");

    const notBus: Route = { ...route, type: 1, id: "Red" };
    expect(busClass(notBus)).toBe("");
  });
});

import React from "react";
import renderer from "react-test-renderer";
import { shallow } from "enzyme";
import StopCard from "../components/StopCard";
import { createReactRoot } from "../../app/helpers/testUtils";
import {
  TNMDirection,
  TNMHeadsign,
  TNMRoute,
  TNMStop,
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

const stop: TNMStop = {
  accessibility: ["wheelchair"],
  address: "123 Main St., Boston MA",
  bike_storage: [],
  closed_stop_info: null,
  fare_facilities: [],
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

const route: TNMRoute = {
  alert_count: 0,
  direction_destinations: ["Outbound Destination", "Inbound Destination"],
  direction_names: ["Outbound", "Inbound"],
  id: "route-id",
  name: "Route Name",
  header: "Route Header",
  long_name: "Route Long Name",
  description: "Route Description",
  stops: [stop],
  type: 1
};

it("it renders a stop card", () => {
  createReactRoot();
  const tree = renderer
    .create(<StopCard stop={stop} route={route} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("returns null if stop has no schedules", () => {
  const stopWithoutSchedules: TNMStop = {
    ...stop,
    directions: [{ ...direction, headsigns: [] }]
  };
  const tree = renderer
    .create(
      <StopCard stop={stopWithoutSchedules} route={route} dispatch={() => {}} />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it selects stop when the card is clicked", () => {
  createReactRoot();

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <StopCard stop={stop} route={route} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__route-stop").simulate("click");
  expect(mockDispatch).toHaveBeenCalledWith({
    type: "CLICK_STOP_CARD",
    payload: { stopId: "stop-id" }
  });
});

it("it selects stop when the card is selected via keyboard", () => {
  createReactRoot();

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <StopCard stop={stop} route={route} dispatch={mockDispatch} />
  );

  wrapper
    .find(".m-tnm-sidebar__route-stop")
    .simulate("keyPress", { key: "Enter" });
  expect(mockDispatch).toHaveBeenCalledWith({
    type: "CLICK_STOP_CARD",
    payload: { stopId: "stop-id" }
  });
});

it("it does nothing when the keyboard event is not enter", () => {
  createReactRoot();

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <StopCard stop={stop} route={route} dispatch={mockDispatch} />
  );

  wrapper
    .find(".m-tnm-sidebar__route-stop")
    .simulate("keyPress", { key: "Tab" });
  expect(mockDispatch).not.toHaveBeenCalled();
});

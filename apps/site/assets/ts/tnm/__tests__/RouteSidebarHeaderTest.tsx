import React from "react";
import renderer from "react-test-renderer";
import { shallow } from "enzyme";
import RouteSidebarHeader from "../components/RouteSidebarHeader";
import { createReactRoot } from "../../app/helpers/testUtils";
import { TNMStop } from "../components/__tnm";

/* eslint-disable typescript/camelcase */

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
  directions: [],
  href: "/stops/stop-id"
};

it("it renders with no stop selected", () => {
  createReactRoot();

  const tree = renderer
    .create(<RouteSidebarHeader selectedStop={undefined} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it renders with a stop selected", () => {
  createReactRoot();

  const tree = renderer
    .create(<RouteSidebarHeader selectedStop={stop} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it deselects a stop when the pill is clicked", () => {
  createReactRoot();

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <RouteSidebarHeader selectedStop={stop} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__pill").simulate("click");
  expect(mockDispatch).toHaveBeenCalledWith({
    payload: { stopId: null },
    type: "CLICK_STOP_PILL"
  });
});

it("it deselects a stop when the pill is selected via keyboard ENTER", () => {
  createReactRoot();

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <RouteSidebarHeader selectedStop={stop} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__pill").simulate("keyPress", { key: "Enter" });
  expect(mockDispatch).toHaveBeenCalledWith({
    payload: { stopId: null },
    type: "CLICK_STOP_PILL"
  });
});

it("it deselects a stop when the pill is selected via a different keyboard event", () => {
  createReactRoot();

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <RouteSidebarHeader selectedStop={stop} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__pill").simulate("keyPress", { key: "Tab" });
  expect(mockDispatch).not.toHaveBeenCalled();
});

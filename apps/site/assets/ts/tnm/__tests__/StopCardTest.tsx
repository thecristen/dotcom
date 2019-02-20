import React from "react";
import renderer from "react-test-renderer";
import { shallow } from "enzyme";
import StopCard from "../components/StopCard";
import { createReactRoot, importData } from "./helpers/testUtils";
import { Route, Stop } from "../components/__tnm";

it("it renders a stop card", () => {
  const data = importData();
  const route: Route = data[0] as Route;
  const stop: Stop = route.stops[0];

  createReactRoot();
  const tree = renderer
    .create(<StopCard stop={stop} route={route} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("returns null if stop has no schedules", () => {
  const data = importData();
  const route: Route = data[0];
  const stop: Stop = route.stops[0];

  expect(stop.directions.length).toBe(1);
  stop.directions[0].headsigns = [];

  const tree = renderer
    .create(<StopCard stop={stop} route={route} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it selects stop when the card is clicked", () => {
  createReactRoot();

  const data = importData();
  const route: Route = data[0];
  const stop: Stop = route.stops[0];

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <StopCard stop={stop} route={route} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__stop").simulate("click");
  expect(mockDispatch).toHaveBeenCalledWith({
    type: "CLICK_STOP_CARD",
    payload: { stopId: "9983" }
  });
});

it("it selects stop when the card is selected via keyboard", () => {
  createReactRoot();

  const data = importData();
  const route: Route = data[0];
  const stop: Stop = route.stops[0];

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <StopCard stop={stop} route={route} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__stop").simulate("keyPress", { key: "Enter" });
  expect(mockDispatch).toHaveBeenCalledWith({
    type: "CLICK_STOP_CARD",
    payload: { stopId: "9983" }
  });
});

it("it does nothing when the keyboard event is not enter", () => {
  createReactRoot();

  const data = importData();
  const route: Route = data[0];
  const stop: Stop = route.stops[0];

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <StopCard stop={stop} route={route} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__stop").simulate("keyPress", { key: "Tab" });
  expect(mockDispatch).not.toHaveBeenCalled();
});

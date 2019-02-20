import React from "react";
import renderer from "react-test-renderer";
import { shallow } from "enzyme";
import RouteSidebarHeader from "../components/RouteSidebarHeader";
import { createReactRoot, importData } from "./helpers/testUtils";
import { Stop } from "../components/__tnm";

it("it renders with no stop selected", () => {
  createReactRoot();

  const tree = renderer
    .create(<RouteSidebarHeader selectedStop={undefined} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it renders with a stop selected", () => {
  createReactRoot();

  const data = importData();

  const stop: Stop = data[0].stops[0];

  const tree = renderer
    .create(<RouteSidebarHeader selectedStop={stop} dispatch={() => {}} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it deselects a stop when the pill is clicked", () => {
  createReactRoot();

  const data = importData();

  const stop: Stop = data[0].stops[0];

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

  const data = importData();

  const stop: Stop = data[0].stops[0];

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

  const data = importData();

  const stop: Stop = data[0].stops[0];

  const mockDispatch = jest.fn();

  const wrapper = shallow(
    <RouteSidebarHeader selectedStop={stop} dispatch={mockDispatch} />
  );

  wrapper.find(".m-tnm-sidebar__pill").simulate("keyPress", { key: "Tab" });
  expect(mockDispatch).not.toHaveBeenCalled();
});

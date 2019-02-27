import React from "react";
import renderer from "react-test-renderer";
import { shallow } from "enzyme";
import StopWithRoutesCard, {
  renderRoutesLabel
} from "../components/StopWithRoutesCard";
import { createReactRoot, importStopData } from "./helpers/testUtils";
import { StopWithRoutes, Route } from "../components/__tnm";

describe("StopWithRoutesCard", () => {
  it("it renders a stop card", () => {
    const data = importStopData();
    const { routes } = data[0] as StopWithRoutes;
    const { stop } = data[0] as StopWithRoutes;

    createReactRoot();
    const tree = renderer
      .create(
        <StopWithRoutesCard stop={stop} routes={routes} dispatch={() => {}} />
      )
      .toJSON();
    expect(tree).toMatchSnapshot();
  });

  it("it selects a stop by triggering the stop card action on click", () => {
    const mockDispatch = jest.fn();
    const data = importStopData();
    const { routes } = data[0] as StopWithRoutes;
    const { stop } = data[0] as StopWithRoutes;

    const wrapper = shallow(
      <StopWithRoutesCard stop={stop} routes={routes} dispatch={mockDispatch} />
    );

    wrapper.find(".m-tnm-sidebar__stop-card").simulate("click");
    expect(mockDispatch).toHaveBeenCalledWith({
      type: "CLICK_STOP_CARD",
      payload: { stopId: "9983" }
    });
  });

  it("it selects a stop by triggering the stop card action via ENTER key", () => {
    const mockDispatch = jest.fn();
    const data = importStopData();
    const { routes } = data[0] as StopWithRoutes;
    const { stop } = data[0] as StopWithRoutes;

    const wrapper = shallow(
      <StopWithRoutesCard stop={stop} routes={routes} dispatch={mockDispatch} />
    );

    wrapper
      .find(".m-tnm-sidebar__stop-card")
      .simulate("keyPress", { key: "Enter" });
    expect(mockDispatch).toHaveBeenCalledWith({
      type: "CLICK_STOP_CARD",
      payload: { stopId: "9983" }
    });
  });
});

it("renderRoutesLabel with commuter rail specific label", () => {
  const data = importStopData();
  const { routes } = data[0] as StopWithRoutes;
  const routesForStop = routes[0].routes as Route[];
  const wrapper = shallow(renderRoutesLabel(routesForStop, "commuter_rail"));
  expect(wrapper.text()).toEqual("Commuter Rail");
});

it("renderRoutesLabel with commuter rail specific label", () => {
  const data = importStopData();
  const { routes } = data[0] as StopWithRoutes;
  const routesForStop = routes[0].routes as Route[];
  const wrapper = shallow(renderRoutesLabel(routesForStop, "bus"));
  expect(wrapper.contains("Bus: ")).toBeTruthy();
});

it("renderRoutesLabel for subway", () => {
  const data = importStopData();
  const { routes } = data[0] as StopWithRoutes;
  const routesForStop = routes[0].routes as Route[];
  const wrapper = shallow(renderRoutesLabel(routesForStop, "subway"));
  expect(wrapper.text()).not.toEqual("Commuter Rail");
  expect(wrapper.contains("Bus: ")).toBeFalsy();
});

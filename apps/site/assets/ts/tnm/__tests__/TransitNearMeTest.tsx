import React from "react";
import renderer from "react-test-renderer";
import { mount } from "enzyme";
import TransitNearMe, { getSelectedStop } from "../components/TransitNearMe";
import { createReactRoot } from "../../app/helpers/testUtils";
import { importData, importStopData } from "./helpers/testUtils";
import { MapData } from "../../app/googleMaps/__googleMaps";

it("it renders", () => {
  /* eslint-disable typescript/camelcase */
  const mapData: MapData = {
    zoom: 14,
    width: 630,
    scale: 1,
    reset_bounds_on_update: false, // eslint-disable-line
    paths: [],
    markers: [],
    default_center: { latitude: 0, longitude: 0 },
    height: 500,
    dynamic_options: {},
    layers: { transit: false },
    auto_init: false,
    bound_padding: null
  };
  /* eslint-enable typescript/camelcase */

  const mapId = "test";
  const routeSidebarData = importData().slice(0, 3);
  const stopSidebarData = importStopData();

  createReactRoot();

  const tree = renderer
    .create(
      <TransitNearMe
        mapData={mapData}
        mapId={mapId}
        routeSidebarData={routeSidebarData}
        stopSidebarData={stopSidebarData}
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it switches view on click", () => {
  /* eslint-disable typescript/camelcase */
  const mapData: MapData = {
    zoom: 14,
    width: 630,
    scale: 1,
    reset_bounds_on_update: false, // eslint-disable-line
    paths: [],
    markers: [],
    default_center: { latitude: 0, longitude: 0 },
    height: 500,
    dynamic_options: {},
    layers: { transit: false },
    auto_init: false,
    bound_padding: null
  };
  /* eslint-enable typescript/camelcase */

  const mapId = "test";
  const routeSidebarData = importData().slice(0, 3);
  const stopSidebarData = importStopData();

  createReactRoot();

  const wrapper = mount(
    <TransitNearMe
      mapData={mapData}
      mapId={mapId}
      routeSidebarData={routeSidebarData}
      stopSidebarData={stopSidebarData}
    />
  );
  wrapper.find(".m-tnm-sidebar__view-change").simulate("click");
  expect(wrapper.exists("#tnm-sidebar-by-stops")).toBeTruthy();
});

it("getSelectedStop returns the stop if found", () => {
  const data = importStopData();
  expect(getSelectedStop(data, data[0].stop.id)).toEqual(data[0].stop);
});

it("getSelectedStop returns undefined if not found", () => {
  const data = importStopData();
  expect(getSelectedStop(data, "unknown")).toEqual(undefined);
});

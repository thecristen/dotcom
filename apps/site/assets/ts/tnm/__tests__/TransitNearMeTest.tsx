import React from "react";
import renderer from "react-test-renderer";
import TransitNearMe from "../components/TransitNearMe";
import { createReactRoot } from "./helpers/testUtils";
import tnmData from "./tnmData.json";
import { Route } from "../components/__tnm";

it("it renders", () => {
  const mapData = {
    zoom: 14,
    width: 630,
    scale: 1,
    reset_bounds_on_update: false, // eslint-disable-line
    paths: [],
    markers: []
  };
  const mapId = "test";
  const sidebarData = tnmData.slice(0, 3) as Array<Route>;
  const getSidebarOffset = () => 3;

  createReactRoot();

  const tree = renderer
    .create(
      <TransitNearMe
        mapData={mapData}
        mapId={mapId}
        sidebarData={sidebarData}
        getSidebarOffset={getSidebarOffset}
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

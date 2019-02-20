import React from "react";
import renderer from "react-test-renderer";
import TransitNearMe from "../components/TransitNearMe";
import { createReactRoot, importData } from "./helpers/testUtils";
import { MapData } from "../components/__tnm";

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
  const sidebarData = importData().slice(0, 3);

  createReactRoot();

  const tree = renderer
    .create(
      <TransitNearMe
        mapData={mapData}
        mapId={mapId}
        sidebarData={sidebarData}
        getSidebarOffset={() => 3}
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

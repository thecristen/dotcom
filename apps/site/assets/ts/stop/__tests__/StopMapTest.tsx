import React from "react";
import renderer from "react-test-renderer";
import StopMap from "../components/StopMap";
import { createReactRoot } from "../../app/helpers/testUtils";
import { StopMapData } from "../components/__stop";

const initialData: StopMapData = {
  // eslint-disable-next-line typescript/camelcase
  map_data: {
    zoom: 14,
    width: 630,
    /* eslint-disable typescript/camelcase */
    markers: [
      {
        id: "current-stop",
        latitude: 25,
        longitude: 25,
        icon: null,
        "visible?": true,
        size: "medium",
        tooltip: null,
        z_index: 1
      }
    ],
    default_center: {
      latitude: 0,
      longitude: 0
    },
    height: 630,
    tile_server_url: ""
  },
  map_srcset: "",
  map_url: ""
  /* eslint-enable typescript/camelcase */
};

it("it renders with initial markers", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <StopMap
        mapElementId="test"
        dispatch={() => {}}
        selectedStopId={null}
        initialData={initialData}
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it doesn't render if it can't find it's mapElement div", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <StopMap
        mapElementId="unknown"
        dispatch={() => {}}
        selectedStopId={null}
        initialData={initialData}
      />
    )
    .toJSON();
  expect(tree).toEqual(null);
});

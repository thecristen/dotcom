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
    scale: 1,
    reset_bounds_on_update: false, // eslint-disable-line
    paths: [],
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
        z_index: 1,
        label: null
      }
    ],
    default_center: {
      latitude: 0,
      longitude: 0
    },
    height: 630,
    dynamic_options: {},
    layers: { transit: true },
    auto_init: true,
    bound_padding: null
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

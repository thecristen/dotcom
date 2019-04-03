import React from "react";
import renderer from "react-test-renderer";
import TransitNearMeMap from "../components/TransitNearMeMap";
import { createReactRoot } from "../../app/helpers/testUtils";

it("it renders without initial markers", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <TransitNearMeMap
        mapElementId="test"
        dispatch={() => {}}
        selectedStopId={null}
        stopData={[]}
        selectedModes={[]}
        shouldFilterMarkers={false}
        shouldCenterMapOnSelectedStop={false}
        /* eslint-disable typescript/camelcase */
        initialData={{
          default_center: {
            latitude: 0,
            longitude: 0
          },
          zoom: 14,
          width: 630,
          height: 630,
          scale: 1,
          reset_bounds_on_update: false,
          paths: [],
          markers: [],
          dynamic_options: {},
          layers: { transit: false },
          auto_init: true,
          bound_padding: null
        }}
        /* eslint-enable typescript/camelcase */
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it renders with initial markers", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <TransitNearMeMap
        mapElementId="test"
        dispatch={() => {}}
        selectedStopId={null}
        stopData={[]}
        selectedModes={[]}
        shouldFilterMarkers={false}
        shouldCenterMapOnSelectedStop={false}
        initialData={{
          zoom: 14,
          width: 630,
          scale: 1,
          reset_bounds_on_update: false, // eslint-disable-line
          paths: [],
          /* eslint-disable typescript/camelcase */
          markers: [
            {
              id: "current-location",
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
          layers: { transit: false },
          auto_init: true,
          bound_padding: null
        }}
        /* eslint-enable typescript/camelcase */
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

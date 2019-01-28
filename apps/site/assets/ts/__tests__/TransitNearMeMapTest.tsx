import React from "react";
import renderer from "react-test-renderer";
import TransitNearMeMap from "../tnm/components/TransitNearMeMap";
import createReactRoot from "./helpers/testUtils";

it("it renders without initial markers", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <TransitNearMeMap
        mapElementId="test"
        initialData={{
          zoom: 14,
          width: 630,
          scale: 1,
          reset_bounds_on_update: false, // eslint-disable-line
          paths: [],
          markers: []
        }}
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
        initialData={{
          zoom: 14,
          width: 630,
          scale: 1,
          reset_bounds_on_update: false, // eslint-disable-line
          paths: [],
          markers: [{ id: "current-location", latitude: 25, longitude: 25 }]
        }}
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

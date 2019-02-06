import React from "react";
import renderer from "react-test-renderer";
import RoutesSidebar from "../components/RoutesSidebar";
import { createReactRoot, createMarkers } from "./helpers/testUtils";
import tnmData from "./tnmData.json";
import { Route } from "../components/__tnm";

it("it renders", () => {
  const data = tnmData.slice(0, 3) as Array<Route>;

  createReactRoot();
  const markers = createMarkers();
  const tree = renderer
    .create(<RoutesSidebar data={data} markers={markers} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it returns null when there isn't data", () => {
  createReactRoot();
  const markers = createMarkers();
  const tree = renderer
    .create(<RoutesSidebar data={[]} markers={markers} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

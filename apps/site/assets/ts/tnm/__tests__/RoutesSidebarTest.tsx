import React from "react";
import renderer from "react-test-renderer";
import RoutesSidebar from "../components/RoutesSidebar";
import createReactRoot from "./helpers/testUtils";
import tnmData from "./tnmData.json";
import { Route } from "../components/__tnm";

it("it renders", () => {
  const data = tnmData.slice(0, 3) as Array<Route>;

  createReactRoot();
  const tree = renderer.create(<RoutesSidebar data={data} />).toJSON();
  expect(tree).toMatchSnapshot();
});

it("it returns null when there isn't data", () => {
  createReactRoot();
  const tree = renderer.create(<RoutesSidebar data={[]} />).toJSON();
  expect(tree).toMatchSnapshot();
});

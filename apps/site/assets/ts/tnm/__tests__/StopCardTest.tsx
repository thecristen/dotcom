import React from "react";
import renderer from "react-test-renderer";
import StopCard from "../components/StopCard";
import createReactRoot from "./helpers/testUtils";
import { Route, Stop } from "../components/__tnm";
import tnmData from "./tnmData.json";

it("it renders a stop card", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0] as Route;
  const stop: Stop = route.stops[0];

  createReactRoot();
  const tree = renderer.create(<StopCard stop={stop} route={route} />).toJSON();
  expect(tree).toMatchSnapshot();
});

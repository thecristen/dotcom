import React from "react";
import renderer from "react-test-renderer";
import { createReactRoot } from "../../app/helpers/testUtils";
import MapTooltip from "../components/MapTooltip";
import stopData from "./stopData.json";
import { StopPageData } from "../components/__stop";
import { Route } from "../../__v3api";

const data: StopPageData = JSON.parse(JSON.stringify(stopData));

const routes: Route[] = [
  {
    type: 1,
    name: "Orange Line",
    long_name: "Orange Line", // eslint-disable-line typescript/camelcase
    id: "Orange",
    direction_names: { "0": "South", "1": "North" }, // eslint-disable-line typescript/camelcase
    direction_destinations: { "0": "Forest Hills", "1": "Oak Grove" }, // eslint-disable-line typescript/camelcase
    description: "rapid_transit",
    alert_count: 0, // eslint-disable-line typescript/camelcase
    header: ""
  }
];

it("it renders", () => {
  createReactRoot();
  const tree = renderer
    .create(<MapTooltip stop={data.stop} routes={routes} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

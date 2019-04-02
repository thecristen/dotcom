import React from "react";
import renderer from "react-test-renderer";
import stopData from "./stopData.json";
import { StopPageData } from "../components/__stop";
import { createReactRoot } from "../../app/helpers/testUtils";
import Departures from "../components/Departures";

it("it renders", () => {
  const data = JSON.parse(JSON.stringify(stopData)) as StopPageData;

  createReactRoot();
  const tree = renderer
    .create(<Departures routes={data.routes} stop={data.stop} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

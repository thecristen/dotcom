import React from "react";
import renderer from "react-test-renderer";
import stopData from "./stopData.json";
import { StopPageData } from "../components/__stop";
import AddressBlock from "../components/AddressBlock";

const data = JSON.parse(JSON.stringify(stopData)) as StopPageData;

it("renders", () => {
  document.body.innerHTML =
    '<div><div id="react-root"><div id="test"></div></div></div>';

  const tree = renderer.create(<AddressBlock routes={data.routes} />).toJSON();

  expect(tree).toMatchSnapshot();
});

import React from "react";
import renderer from "react-test-renderer";
import StopPage from "../components/StopPage";
import stopData from "./stopData.json";
import StopPageData from "../components/__stop";

it("it renders", () => {
  const data = JSON.parse(JSON.stringify(stopData)) as StopPageData;

  document.body.innerHTML =
    '<div><div id="react-root"><div id="test"></div></div></div>';
  const tree = renderer.create(<StopPage stopPageData={data} />).toJSON();
  expect(tree).toMatchSnapshot();
});

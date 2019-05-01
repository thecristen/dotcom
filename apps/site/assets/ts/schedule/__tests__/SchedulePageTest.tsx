import React from "react";
import renderer from "react-test-renderer";
import { createReactRoot } from "../../app/helpers/testUtils";
import SchedulePage from "../components/SchedulePage";

const pdfs = [
  {
    url: "https://mbta.com/example-pdf.pdf",
    title: "Route 1 schedule PDF"
  }
];

it("it renders", () => {
  createReactRoot();
  const tree = renderer
    .create(<SchedulePage schedulePageData={{ pdfs }} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

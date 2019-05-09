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

const teasers = `<div><a href="http://some-link">Some teaser from CMS></a></div>`;

it("it renders", () => {
  createReactRoot();
  const tree = renderer
    .create(<SchedulePage schedulePageData={{ pdfs, teasers }} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

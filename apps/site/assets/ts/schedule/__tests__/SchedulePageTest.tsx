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

const hours = `<div class="m-schedule-page__sidebar-hours">  <h3 class="hours-period-heading">Monday to Friday</h3>
<p class="hours-directions">
  <span class="hours-direction-name">Inbound</span>
  <span class="hours-time">04:17A-12:46A</span>
</p>
<p class="hours-directions">
  <span class="hours-direction-name">Outbound</span>
  <span class="hours-time">05:36A-01:08A</span>
</p>
</div>`;

const fares = [
  {
    title: "CharlieCard",
    price: "$2.25"
  },
  {
    title: "CharlieTicket or Cash",
    price: "$2.75"
  }
];

const fareLink = "/fares/bus-fares";

it("it renders", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <SchedulePage
        // eslint-disable-next-line typescript/camelcase
        schedulePageData={{ pdfs, teasers, hours, fares, fare_link: fareLink }}
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

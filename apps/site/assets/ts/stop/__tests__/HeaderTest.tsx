import React from "react";
import renderer from "react-test-renderer";
import { shallow } from "enzyme";
import stopData from "./stopData.json";
import { StopPageData, TypedRoutes } from "../components/__stop";
import Header from "../components/Header";
import { createReactRoot } from "../../app/helpers/testUtils";

const data = JSON.parse(JSON.stringify(stopData)) as StopPageData;

it("renders", () => {
  createReactRoot();
  const tree = renderer
    .create(
      <Header
        stop={data.stop}
        routes={data.routes}
        zoneNumber={data.zone_number}
        tabs={data.tabs}
      />
    )
    .toJSON();

  expect(tree).toMatchSnapshot();
});

it("renders with green line routes", () => {
  /* eslint-disable typescript/camelcase */
  const routes: TypedRoutes[] = [
    {
      group_name: "subway",
      routes: [
        {
          type: 1,
          name: "Green Line",
          header: "Green Line",
          long_name: "Green Line",
          id: "Green",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        },
        {
          type: 1,
          name: "B Line",
          header: "B Line",
          long_name: "B Line",
          id: "Green-B",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        },
        {
          type: 1,
          name: "C Line",
          header: "C Line",
          long_name: "C Line",
          id: "Green-C",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        },
        {
          type: 1,
          name: "D Line",
          header: "D Line",
          long_name: "D Line",
          id: "Green-D",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        },
        {
          type: 1,
          name: "E Line",
          header: "E Line",
          long_name: "E Line",
          id: "Green-E",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        }
      ]
    }
  ];
  /* eslint-enable typescript/camelcase */

  const tree = renderer
    .create(
      <Header
        stop={data.stop}
        routes={routes}
        zoneNumber={data.zone_number}
        tabs={data.tabs}
      />
    )
    .toJSON();

  expect(tree).toMatchSnapshot();
});

it("renders all subway routes", () => {
  /* eslint-disable typescript/camelcase */
  const routes: TypedRoutes[] = [
    {
      group_name: "subway",
      routes: [
        {
          type: 1,
          name: "Red Line",
          header: "Red Line",
          long_name: "Red Line",
          id: "Red",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        },
        {
          type: 1,
          name: "Orange Line",
          header: "Orange Line",
          long_name: "Orange Line",
          id: "Orange",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        },
        {
          type: 1,
          name: "Blue Line",
          header: "Blue Line",
          long_name: "Blue Line",
          id: "Blue",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        },
        {
          type: 1,
          name: "Mattapan Line",
          header: "Mattapan Line",
          long_name: "Mattapan Line",
          id: "Mattapan",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        }
      ]
    }
  ];
  /* eslint-enable typescript/camelcase */

  const tree = renderer
    .create(
      <Header
        stop={data.stop}
        routes={routes}
        zoneNumber={data.zone_number}
        tabs={data.tabs}
      />
    )
    .toJSON();

  expect(tree).toMatchSnapshot();
});

it("renders a ferry route", () => {
  /* eslint-disable typescript/camelcase */
  const routes: TypedRoutes[] = [
    {
      group_name: "ferry",
      routes: [
        {
          type: 4,
          name: "Charlestown Ferry",
          header: "Charlestown Ferry",
          long_name: "Charlestown Ferry",
          id: "Boat-F4",
          direction_names: { "0": "Outbound", "1": "Inbound" },
          direction_destinations: { "0": "Charlestown", "1": "Long Wharf" },
          description: "ferry",
          alert_count: 0,
          stops: []
        }
      ]
    }
  ];
  /* eslint-enable typescript/camelcase */

  const tree = renderer
    .create(
      <Header
        stop={data.stop}
        routes={routes}
        zoneNumber={data.zone_number}
        tabs={data.tabs}
      />
    )
    .toJSON();

  expect(tree).toMatchSnapshot();
});

it("upcases name of non-bus stops", () => {
  /* eslint-disable typescript/camelcase */
  const routes: TypedRoutes[] = [
    {
      group_name: "bus",
      routes: [
        {
          type: 3,
          name: "Bus",
          header: "Bus",
          long_name: "Bus",
          id: "Bus",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        }
      ]
    },
    {
      group_name: "subway",
      routes: [
        {
          type: 1,
          name: "Orange Line",
          header: "Orange Line",
          long_name: "Orange Line",
          id: "Orange",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        }
      ]
    }
  ];
  /* eslint-enable typescript/camelcase */

  const wrapper = shallow(
    <Header
      stop={data.stop}
      routes={routes}
      zoneNumber={data.zone_number}
      tabs={data.tabs}
    />
  );
  expect(wrapper.find(".m-stop-page__name")).toHaveLength(1);
  expect(wrapper.find(".m-stop-page__name--upcase")).toHaveLength(1);
});

it("does not upcase name of bus-only stops", () => {
  /* eslint-disable typescript/camelcase */
  const routes: TypedRoutes[] = [
    {
      group_name: "bus",
      routes: [
        {
          type: 3,
          name: "Bus",
          header: "Bus",
          long_name: "Bus",
          id: "Bus",
          direction_names: {
            "0": "South",
            "1": "North"
          },
          direction_destinations: {
            "0": "Ashmont/Braintree",
            "1": "Alewife"
          },
          description: "rapid_transit",
          alert_count: 0,
          stops: []
        }
      ]
    }
  ];
  /* eslint-enable typescript/camelcase */

  const wrapper = shallow(
    <Header
      stop={data.stop}
      routes={routes}
      zoneNumber={data.zone_number}
      tabs={data.tabs}
    />
  );
  expect(wrapper.find(".m-stop-page__name")).toHaveLength(1);
  expect(wrapper.find(".m-stop-page__name--upcase")).toHaveLength(0);
});

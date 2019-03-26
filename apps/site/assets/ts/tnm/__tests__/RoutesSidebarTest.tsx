import React from "react";
import renderer from "react-test-renderer";
import RoutesSidebar, { filterData } from "../components/RoutesSidebar";
import { createReactRoot } from "../../app/helpers/testUtils";
import { importData } from "./helpers/testUtils";
import { TNMRoute } from "../components/__tnm";

describe("render", () => {
  it("it renders", () => {
    const data = importData().slice(0, 3);

    createReactRoot();
    const tree = renderer
      .create(
        <RoutesSidebar
          data={data}
          selectedStopId={null}
          shouldFilterStopCards={false}
          dispatch={() => {}}
          selectedStop={undefined}
          selectedModes={[]}
        />
      )
      .toJSON();
    expect(tree).toMatchSnapshot();
  });

  it("it returns null when there isn't data", () => {
    createReactRoot();
    const tree = renderer
      .create(
        <RoutesSidebar
          data={[]}
          selectedStopId={null}
          shouldFilterStopCards={false}
          dispatch={() => {}}
          selectedStop={undefined}
          selectedModes={[]}
        />
      )
      .toJSON();
    expect(tree).toEqual(null);
  });
});

describe("filterData", () => {
  it("should filter by stop ID", () => {
    const data = importData();
    const selectedStopId = data[0].stops[0].id;

    expect(data).toHaveLength(26);

    const filteredData = filterData(data, selectedStopId, [], true);

    expect(filteredData).toHaveLength(3);

    // Every route should only have one stop
    expect(filteredData.every((route: TNMRoute) => route.stops.length === 1));

    // Every stop should match the selected stop
    expect(
      filteredData.every(
        (route: TNMRoute) => route.stops[0].id === selectedStopId
      )
    );
  });

  it("should filter by modes", () => {
    const data = importData();
    expect(data).toHaveLength(26);

    const filteredBusData = filterData(data, null, ["bus"], true);
    expect(filteredBusData).toHaveLength(12);
    expect(filteredBusData.every((route: TNMRoute) => route.type === 3));

    const filteredRailData = filterData(data, null, ["rail"], true);
    expect(filteredRailData).toHaveLength(8);
    expect(filteredRailData.every((route: TNMRoute) => route.type === 2));

    const filteredSubwayData = filterData(data, null, ["subway"], true);
    expect(filteredSubwayData).toHaveLength(6);
    expect(
      filteredSubwayData.every(
        (route: TNMRoute) => route.type === 0 || route.type === 1
      )
    );
  });
});

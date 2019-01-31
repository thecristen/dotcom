import React from "react";
import renderer from "react-test-renderer";
import RouteCard, {
  isSilverLine,
  routeBgColor,
  busClass
} from "../components/RouteCard";
import createReactRoot from "./helpers/testUtils";
import { Route } from "../components/__tnm";
import tnmData from "./tnmData.json";

it("it renders a stop card", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0] as Route;

  createReactRoot();
  const tree = renderer.create(<RouteCard route={route} />).toJSON();
  expect(tree).toMatchSnapshot();
});

it("it renders a stop card for the silver line", () => {
  const data: Array<Route> = JSON.parse(JSON.stringify(tnmData));
  let route = data.find(r => r.id == "751") as Route;

  expect(route).not.toBeNull;

  createReactRoot();
  const tree = renderer.create(<RouteCard route={route} />).toJSON();
  expect(tree).toMatchSnapshot();
});

describe("isSilverLine", () => {
  it("identifies silver line routes", () => {
    const data = JSON.parse(JSON.stringify(tnmData));
    const route: Route = data[0] as Route;

    ["741", "742", "743", "746", "749", "751"].forEach(sl => {
      route.id = sl;
      expect(isSilverLine(route)).toBe(true);
    });
  });
});

describe("routeBgColor", () => {
  it("determines the background color by route", () => {
    const data = JSON.parse(JSON.stringify(tnmData));
    const route: Route = data[0] as Route;

    route.type = 2;
    expect(routeBgColor(route)).toBe("commuter-rail");

    route.type = 4;
    expect(routeBgColor(route)).toBe("ferry");

    route.type = 1;
    ["Red", "Orange", "Blue"].forEach(id => {
      route.id = id;
      expect(routeBgColor(route)).toBe(`${id.toLowerCase()}-line`);
    });

    route.type = 0;
    route.id = "Green-B";
    expect(routeBgColor(route)).toBe("green-line");

    route.type = 3;
    route.id = "1";
    expect(routeBgColor(route)).toBe("bus");

    route.type = 6;
    route.id = "fakeID";
    expect(routeBgColor(route)).toBe("unknown");
  });
});

describe("busClass", () => {
  it("determines a route is a bus route", () => {
    const data = JSON.parse(JSON.stringify(tnmData));
    const route: Route = data[0] as Route;

    route.type = 3;
    route.id = "1";
    expect(busClass(route)).toBe("bus-route-sign");

    route.type = 1;
    route.id = "Red";
    expect(busClass(route)).toBe("");
  });
});

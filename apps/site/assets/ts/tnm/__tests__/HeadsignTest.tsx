import React from "react";
import renderer from "react-test-renderer";
import Headsign from "../components/Headsign";
import createReactRoot from "./helpers/testUtils";
import { Route, Stop, TNMDirection, TNMHeadsign } from "../components/__tnm";
import tnmData from "./tnmData.json";

it("it renders 2 predictions", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0] as Route;
  const stop: Stop = route.stops[0];
  const direction: TNMDirection = stop.directions[0];
  const headsign: TNMHeadsign = direction.headsigns[0];

  expect(headsign.times[0].prediction).not.toBeNull();
  expect(headsign.times[1].prediction).not.toBeNull();

  createReactRoot();
  const tree = renderer.create(<Headsign headsign={headsign} />).toJSON();
  expect(tree).toMatchSnapshot();
});

it("it renders scheduled time when prediction is null", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0] as Route;
  const stop: Stop = route.stops[0];
  const direction: TNMDirection = stop.directions[0];
  const headsign: TNMHeadsign = direction.headsigns[0];

  expect(headsign.times[0].prediction).not.toBeNull();
  headsign.times[1].prediction = null;

  createReactRoot();
  const tree = renderer.create(<Headsign headsign={headsign} />).toJSON();
  expect(tree).toMatchSnapshot();
});

it("it renders prediction time string", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0] as Route;
  const stop: Stop = route.stops[0];
  const direction: TNMDirection = stop.directions[0];
  const headsign: TNMHeadsign = direction.headsigns[0];

  expect(headsign.times[0].prediction).not.toBeNull();
  expect(headsign.times[1].prediction).not.toBeNull();
  headsign.times[1].prediction!.time = ["10:35", " ", "PM"];

  createReactRoot();
  const tree = renderer.create(<Headsign headsign={headsign} />).toJSON();
  expect(tree).toMatchSnapshot();
});

it("it splits the headsign name when it contains 'via' ", () => {
  const data = JSON.parse(JSON.stringify(tnmData));
  const route: Route = data[0] as Route;
  const stop: Stop = route.stops[0];
  const direction: TNMDirection = stop.directions[0];
  const headsign: TNMHeadsign = direction.headsigns[0];

  expect(headsign.times[0].prediction).not.toBeNull();
  expect(headsign.times[1].prediction).not.toBeNull();
  headsign.name = "Watertown via Harvard Square";

  createReactRoot();
  const tree = renderer.create(<Headsign headsign={headsign} />).toJSON();
  expect(tree).toMatchSnapshot();
});

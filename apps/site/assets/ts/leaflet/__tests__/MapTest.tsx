import React from "react";
import { mount } from "enzyme";
import Map from "../components/Map";
import { MapData } from "../components/__mapdata";

/* eslint-disable typescript/camelcase */
const data: MapData = {
  zoom: 16,
  width: 735,
  markers: [
    {
      z_index: 0,
      "visible?": false,
      tooltip: null,
      size: "mid",
      longitude: -71.071097,
      latitude: 42.43668,
      id: null,
      icon: null
    }
  ],
  height: 250,
  tile_server_url: "https://mbta-map-tiles-dev.s3.amazonaws.com",
  default_center: {
    longitude: -72.05891,
    latitude: 44.360718
  }
};

it("it renders using the marker's position", () => {
  const div = document.createElement("div");
  document.body.appendChild(div);
  const wrapper = mount(<Map mapData={data} />, {
    attachTo: div
  });
  expect(
    wrapper
      .render()
      .find(".leaflet-tile")
      .prop("src")
  ).toBe(`${data.tile_server_url}/osm_tiles/16/19829/24220.png`);
});

it("it renders using the default center position", () => {
  const dataWithoutMarkers: MapData = { ...data, markers: [] };
  const div = document.createElement("div");
  document.body.appendChild(div);
  const wrapper = mount(<Map mapData={dataWithoutMarkers} />, {
    attachTo: div
  });
  expect(
    wrapper
      .render()
      .find(".leaflet-tile")
      .prop("src")
  ).toBe(`${data.tile_server_url}/osm_tiles/16/19650/23738.png`);
});
/* eslint-disable typescript/camelcase */

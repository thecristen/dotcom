import React from "react";
import renderer from "react-test-renderer";
import StopPage from "../components/StopPage";
import stopData from "./stopData.json";
import { StopPageData } from "../components/__stop";
import { MapData } from "../../app/googleMaps/__googleMaps";
import { createReactRoot } from "../../app/helpers/testUtils";

it("it renders", () => {
  const data = JSON.parse(JSON.stringify(stopData)) as StopPageData;
  /* eslint-disable typescript/camelcase */
  const mapData: MapData = {
    zoom: 14,
    width: 630,
    scale: 1,
    reset_bounds_on_update: false, // eslint-disable-line
    paths: [],
    markers: [
      {
        id: "current-stop",
        latitude: 25,
        longitude: 25,
        icon: null,
        "visible?": true,
        size: "medium",
        tooltip: null,
        z_index: 1,
        label: null
      }
    ],
    default_center: { latitude: 0, longitude: 0 },
    height: 500,
    dynamic_options: {},
    layers: { transit: false },
    auto_init: false,
    bound_padding: null
  };

  const initialData = {
    map_data: mapData,
    map_srcset: "",
    map_url: ""
  };
  /* eslint-enable typescript/camelcase */

  createReactRoot();
  const tree = renderer
    .create(<StopPage stopPageData={data} mapId="test" mapData={initialData} />)
    .toJSON();
  expect(tree).toMatchSnapshot();
});

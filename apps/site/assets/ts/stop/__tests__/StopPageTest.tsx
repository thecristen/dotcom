import React from "react";
import renderer from "react-test-renderer";
import StopPage from "../components/StopPage";
import stopData from "./stopData.json";
import { StopPageData } from "../components/__stop";
import { MapData } from "../../leaflet/components/__mapdata";
import { createReactRoot } from "../../app/helpers/testUtils";

it("it renders", () => {
  const data = JSON.parse(JSON.stringify(stopData)) as StopPageData;
  /* eslint-disable typescript/camelcase */
  const mapData: MapData = {
    zoom: 14,
    width: 630,
    markers: [
      {
        id: "current-stop",
        latitude: 25,
        longitude: 25,
        icon: null,
        "visible?": true,
        size: "medium",
        tooltip: null,
        z_index: 1
      }
    ],
    default_center: { latitude: 0, longitude: 0 },
    height: 500,
    tile_server_url: ""
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

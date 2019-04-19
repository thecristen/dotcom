import React, { ReactElement } from "react";
import { StopMapData } from "./__stop";
import { SelectedStopType, Dispatch } from "../state";
import Map from "../../leaflet/components/Map";
import { MapData } from "../../leaflet/components/__mapdata";

interface Props {
  initialData: StopMapData;
  mapElementId: string;
  dispatch: Dispatch;
  selectedStopId: SelectedStopType;
}

/* eslint-disable typescript/camelcase */
export default ({
  initialData: {
    map_data: { default_center, width, height, zoom, markers, tile_server_url }
  }
}: Props): ReactElement<HTMLElement> => {
  const mapData: MapData = {
    zoom: zoom || 12,
    width,
    tile_server_url,
    markers,
    height,
    default_center
  };
  return <Map mapData={mapData} />;
};
/* eslint-enable typescript/camelcase */

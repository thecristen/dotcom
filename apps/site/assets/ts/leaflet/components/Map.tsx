import React, { ReactElement } from "react";
import { Map as LeafletMap, TileLayer } from "react-leaflet";
import { MapData, MapMarker } from "./__mapdata";

interface Props {
  mapData: MapData;
}

const mapCenter = (
  markers: MapMarker[],
  { latitude, longitude }: { latitude: number; longitude: number }
): [number, number] =>
  markers.length === 1
    ? [markers[0].latitude, markers[0].longitude]
    : [latitude, longitude];

/* eslint-disable typescript/camelcase */
export default ({
  mapData: { default_center: defaultCenter, zoom, markers, tile_server_url }
}: Props): ReactElement<HTMLElement> => {
  if (
    tile_server_url === "http://tile-server.mbtace.com" ||
    tile_server_url === "http://dev.tile-server.mbtace.com"
  ) {
    const position = mapCenter(markers, defaultCenter);
    return (
      <LeafletMap center={position} zoom={zoom}>
        <TileLayer
          attribution='&amp;copy <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
          url={`${tile_server_url}/osm_tiles/{z}/{x}/{y}.png`}
        />
      </LeafletMap>
    );
  }

  throw new Error(`unexpected tile_server_url: ${tile_server_url}`);
};
/* eslint-enable typescript/camelcase */

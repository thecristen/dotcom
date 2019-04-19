import React, { ReactElement } from "react";
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

export default ({
  mapData: {
    default_center: defaultCenter,
    zoom,
    markers,
    tile_server_url: tileServerUrl
  }
}: Props): ReactElement<HTMLElement> | null => {
  if (typeof window !== "undefined" && tileServerUrl !== "") {
    /* eslint-disable */
    const icon = require("../icon").default;
    const leaflet = require("react-leaflet");
    /* eslint-enable */
    const { Map, TileLayer, Marker, Popup } = leaflet;
    const position = mapCenter(markers, defaultCenter);
    return (
      <Map center={position} zoom={zoom} maxZoom={18}>
        <TileLayer
          attribution='&amp;copy <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
          url={`${tileServerUrl}/osm_tiles/{z}/{x}/{y}.png`}
        />
        {markers.map(marker => (
          <Marker
            key={marker.id}
            position={[marker.latitude, marker.longitude]}
            icon={icon(marker.icon)}
            onClick={marker.onClick}
          >
            {marker.tooltip && (
              <Popup minWidth={200} maxHeight={200}>
                <div
                  style={{ paddingBottom: "10px" }}
                  // eslint-disable-next-line react/no-danger
                  dangerouslySetInnerHTML={{ __html: marker.tooltip }}
                />
              </Popup>
            )}
          </Marker>
        ))}
      </Map>
    );
  }
  return null;
};

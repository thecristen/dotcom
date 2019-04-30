import React, { ReactElement } from "react";
import deepEqual from "fast-deep-equal";
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

const Component = ({
  mapData: {
    default_center: defaultCenter,
    markers,
    polylines,
    tile_server_url: tileServerUrl,
    zoom
  }
}: Props): ReactElement<HTMLElement> | null => {
  if (typeof window !== "undefined" && tileServerUrl !== "") {
    /* eslint-disable */
    const icon = require("../icon").default;
    const leaflet = require("react-leaflet");
    /* eslint-enable */
    const { Map, Marker, Polyline, Popup, TileLayer } = leaflet;
    const position = mapCenter(markers, defaultCenter);
    return (
      <Map center={position} zoom={zoom} maxZoom={18}>
        <TileLayer
          attribution='&amp;copy <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
          url={`${tileServerUrl}/osm_tiles/{z}/{x}/{y}.png`}
        />
        {polylines.map(polyline => (
          <Polyline
            key={polyline.id}
            positions={polyline.positions}
            color={polyline.color}
            weight={polyline.weight}
          />
        ))}
        {markers.map(marker => (
          <Marker
            key={marker.id}
            position={[marker.latitude, marker.longitude]}
            icon={icon(marker.icon)}
            onClick={marker.onClick}
          >
            {marker.tooltip && (
              <Popup minWidth={320} maxHeight={175}>
                {marker.tooltip}
              </Popup>
            )}
          </Marker>
        ))}
      </Map>
    );
  }
  return null;
};

export default React.memo(Component, deepEqual);

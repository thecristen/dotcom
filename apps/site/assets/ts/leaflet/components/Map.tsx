import React, { ReactElement } from "react";
import deepEqual from "fast-deep-equal";
import Leaflet from "react-leaflet";
import { Icon } from "leaflet";
import { MapData, MapMarker, IconOpts } from "./__mapdata";

export interface ZoomOpts {
  maxZoom: number;
  minZoom: number;
  scrollWheelZoom: boolean;
}

export const defaultZoomOpts: ZoomOpts = {
  maxZoom: 18,
  minZoom: 11,
  scrollWheelZoom: false
};

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
    const leaflet: typeof Leaflet = require("react-leaflet");
    const buildIcon: (
      icon: string | null,
      opts?: IconOpts
    ) => Icon | undefined = require("../icon").default;
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
            key={marker.id || `marker-${Math.floor(Math.random() * 1000)}`}
            position={[marker.latitude, marker.longitude]}
            icon={buildIcon(marker.icon)}
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

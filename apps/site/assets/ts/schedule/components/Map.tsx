import React, { ReactElement } from "react";
import { LatLng, latLng, LatLngBounds, latLngBounds } from "leaflet";
import Map from "../../leaflet/components/Map";
import {
  MapData,
  MapMarker as Marker
} from "../../leaflet/components/__mapdata";

interface Props {
  data: MapData;
}

export const getBounds = (markers: Marker[]): LatLngBounds => {
  const points: LatLng[] = markers.map(m => latLng(m.latitude, m.longitude));
  return latLngBounds(points);
};

export const iconOpts = (
  icon: string | null
): {
  iconSize?: [number, number];
  iconAnchor?: [number, number];
} => {
  switch (icon) {
    case null:
      return {};

    case "vehicle-bordered-expanded":
      return {
        iconSize: [18, 18],
        iconAnchor: [6, 6]
      };

    case "stop-circle-bordered-expanded":
      return {
        iconSize: [12, 12],
        iconAnchor: [6, 6]
      };

    default:
      throw new Error(`unexpected icon type: ${icon}`);
  }
};

const zIndex = (icon: string | null): number | undefined =>
  icon === "vehicle-bordered-expanded" ? 1000 : undefined;

const updateMarker = (marker: Marker): Marker => ({
  ...marker,
  tooltip: <div>{marker.tooltip_text}</div>,
  iconOpts: iconOpts(marker.icon),
  zIndex: zIndex(marker.icon)
});

export default ({ data }: Props): ReactElement<HTMLElement> => (
  <div className="m-schedule__map">
    <Map
      bounds={getBounds(data.markers)}
      mapData={{ ...data, markers: data.markers.map(updateMarker) }}
    />
  </div>
);

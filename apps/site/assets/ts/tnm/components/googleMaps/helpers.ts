// @ts-ignore
import stopMarker from "../../../../static/images/icon-map-stop-marker.svg";
// @ts-ignore
import stationMarker from "../../../../static/images/icon-map-station-marker.svg";
// @ts-ignore
import selectedStopMarker from "../../../../static/images/icon-map-stop-marker-hover.svg";
// @ts-ignore
import selectedStationMarker from "../../../../static/images/icon-map-station-marker-hover.svg";
// @ts-ignore
import currentLocationMarker from "../../../../static/images/icon-current-location-marker.svg";
import { iconSize } from "../../../../js/google-map/helpers";

import { MarkerData } from "../__tnm";

interface GoogleMapMarkerSVG {
  url: string;
  scaledSize: google.maps.Size;
  origin: google.maps.Point;
  anchor: google.maps.Point;
  labelOrigin: google.maps.Point;
}

export const stopIcon = (selected: boolean): string =>
  selected ? selectedStopMarker : stopMarker;
export const stationIcon = (selected: boolean): string =>
  selected ? selectedStationMarker : stationMarker;

export const buildIconFromSVG = (
  svg: string,
  size: string
): GoogleMapMarkerSVG => {
  const sizeInt = iconSize(size);

  const encoded = window.btoa(svg);

  return {
    url: `data:image/svg+xml;base64, ${encoded}`,
    scaledSize: new window.google.maps.Size(sizeInt, sizeInt),
    origin: new window.google.maps.Point(0, 0),
    anchor: new window.google.maps.Point(sizeInt / 2, sizeInt / 2),
    labelOrigin: new window.google.maps.Point(sizeInt / 2, sizeInt / 2)
  };
};

export const buildMarkerIcon = (
  data: MarkerData,
  selected: boolean
): GoogleMapMarkerSVG | undefined => {
  if (data.icon) {
    if (data.icon!.includes("station")) {
      return buildIconFromSVG(stationIcon(selected), data.size);
    }
    if (data.icon!.includes("stop")) {
      return buildIconFromSVG(stopIcon(selected), data.size);
    }
    if (data.icon!.includes("current-location")) {
      return buildIconFromSVG(currentLocationMarker, data.size);
    }
  }
  return undefined;
};

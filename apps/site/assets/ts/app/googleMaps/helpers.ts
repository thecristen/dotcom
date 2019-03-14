// @ts-ignore
import stopMarker from "../../../static/images/icon-map-stop-marker.svg";
// @ts-ignore
import stationMarker from "../../../static/images/icon-map-station-marker.svg";
// @ts-ignore
import selectedStopMarker from "../../../static/images/icon-map-stop-marker-hover.svg";
// @ts-ignore
import selectedStationMarker from "../../../static/images/icon-map-station-marker-hover.svg";
// @ts-ignore
import currentLocationMarker from "../../../static/images/icon-current-location-marker.svg";
import { iconSize } from "../../../js/google-map/helpers";
import mapStyles from "../../../js/google-map/styles";
import { MarkerData, MapData } from "./__googleMaps";

export const stopIcon = (selected: boolean): string =>
  selected ? selectedStopMarker : stopMarker;
export const stationIcon = (selected: boolean): string =>
  selected ? selectedStationMarker : stationMarker;

export const buildIconFromSVG = (
  svg: string,
  size: string
): google.maps.Icon => {
  const sizeInt = iconSize(size);

  const encoded = window.btoa(svg);

  return {
    url: `data:image/svg+xml;base64, ${encoded}`,
    scaledSize: new window.google.maps.Size(sizeInt, sizeInt),
    origin: new window.google.maps.Point(0, 0),
    labelOrigin: new window.google.maps.Point(sizeInt / 2, sizeInt / 2)
  };
};

export const buildMarkerIcon = (
  data: MarkerData,
  selected: boolean
): google.maps.Icon | undefined => {
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

export const setMapDefaults = (
  map: google.maps.Map,
  initialData: MapData
): void => {
  const options = {
    center: new window.google.maps.LatLng(
      initialData.default_center.latitude,
      initialData.default_center.longitude
    ),
    ...initialData.dynamic_options
  };
  const styles = mapStyles as google.maps.MapTypeStyle[];
  // Hide stop icons on the transit layer
  styles.push({
    featureType: "transit",
    elementType: "labels.icon",
    stylers: [{ visibility: "off" }]
  });
  map.setOptions({ styles, ...options });
  map.setZoom(initialData.zoom || 17);

  if (initialData.layers && initialData.layers.transit) {
    const layer = new window.google.maps.TransitLayer();
    layer!.setMap(map);
  }
};

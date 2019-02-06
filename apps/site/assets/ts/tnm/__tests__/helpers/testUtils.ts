import { SVGMarkers } from "../../components/__tnm";

export const createReactRoot = (): void => {
  document.body.innerHTML =
    '<div><div id="react-root"><div id="test"></div></div></div>';
};

export const createMarkers = (): SVGMarkers => ({
  stopMarker: '<svg id="icon-feature-map-stop-icon"></svg>',
  stationMarker: '<svg id="icon-feature-map-station-icon"></svg>'
});

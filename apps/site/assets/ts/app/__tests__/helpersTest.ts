import { buildIconFromSVG, buildMarkerIcon } from "../googleMaps/helpers";

const defaultMarkerData = {
  id: "1",
  latitude: 0,
  longitude: 0,
  "visible?": true,
  size: "small",
  tooltip: "a tooltip",
  // eslint-disable-next-line
  z_index: 1,
  label: null
};

// Our jest resolver for *.svg files returns "SVG"
// This is "SVG" encoded
const svgEncoded = "data:image/svg+xml;base64, U1ZH";

describe("buildIconFromSVG", () => {
  it("builds a google map icon from a SVG import", () => {
    const markerIcon = buildIconFromSVG(
      '<svg><g id="someString"></svg>',
      "tiny"
    );
    expect(markerIcon.url).toBe(
      "data:image/svg+xml;base64, PHN2Zz48ZyBpZD0ic29tZVN0cmluZyI+PC9zdmc+"
    );
    expect(markerIcon.labelOrigin).toBeInstanceOf(google.maps.Point);
    expect(markerIcon.origin).toBeInstanceOf(google.maps.Point);
    expect(markerIcon.scaledSize).toBeInstanceOf(google.maps.Size);
  });
});

describe("buildMarkerIcon", () => {
  it("builds station icons", () => {
    const station = buildMarkerIcon(
      { icon: "map-station-marker", ...defaultMarkerData },
      false
    );
    const selectedStation = buildMarkerIcon(
      { icon: "map-station-marker", ...defaultMarkerData },
      true
    );
    expect(station!.url).toBe(svgEncoded);
    expect(selectedStation!.url).toBe(svgEncoded);
  });

  it("builds stop icons", () => {
    const stop = buildMarkerIcon(
      { icon: "map-stop-marker", ...defaultMarkerData },
      false
    );
    const selectedStop = buildMarkerIcon(
      { icon: "map-stop-marker", ...defaultMarkerData },
      true
    );
    expect(stop!.url).toBe(svgEncoded);
    expect(selectedStop!.url).toBe(svgEncoded);
  });

  it("builds an current-location icon", () => {
    const currentLocation = buildMarkerIcon(
      { icon: "map-current-location", ...defaultMarkerData },
      false
    );
    expect(currentLocation!.url).toBe(svgEncoded);
  });

  it("returns undefined if no icons are matched", () => {
    const noMarker = buildMarkerIcon(
      { icon: "not-a-supported-icon", ...defaultMarkerData },
      false
    );
    expect(noMarker).toBe(undefined);
  });
});

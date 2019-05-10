import { onClickMarker, buildIcon } from "../components/leaflet/MarkerWrapper";

describe("onClickMarker", () => {
  it("dispatches a current location click action", () => {
    const dispatch = jest.fn();
    const clicked = onClickMarker("current-location", dispatch);
    clicked();
    expect(dispatch).toBeCalledWith({
      payload: { stopId: "current-location" },
      type: "CLICK_CURRENT_LOCATION_MARKER"
    });
  });

  it("dispatches a marker click action", () => {
    const dispatch = jest.fn();
    const clicked = onClickMarker("stop-id", dispatch);
    clicked();
    expect(dispatch).toBeCalledWith({
      payload: { stopId: "stop-id" },
      type: "CLICK_MARKER"
    });
  });
});

describe("buildIcon", () => {
  it("returns undefined if marker icon is null", () => {
    const emptyMarker = buildIcon(null, undefined, false, false);
    expect(emptyMarker).toBeUndefined();
  });

  it("returns a sized marker if the marker is for current location", () => {
    const locMarker = buildIcon(
      "current-location-marker",
      [25, 25],
      false,
      false
    );
    expect(locMarker!.options.iconUrl).toMatch("current-location-marker");
    expect(locMarker!.options.iconSize).toEqual([25, 25]);
  });

  it("returns a hovered state marker if the marker is hovered", () => {
    const locMarker = buildIcon("stop-id", undefined, true, false);
    expect(locMarker!.options.iconUrl).toMatch("-hover");
  });

  it("returns a selected state marker if the marker is selected", () => {
    const locMarker = buildIcon("stop-id", undefined, false, true);
    expect(locMarker!.options.iconUrl).toMatch("-hover");
  });

  it("returns the specified marker if not matched", () => {
    const locMarker = buildIcon("stop-id", undefined, false, false);
    expect(locMarker!.options.iconUrl).toMatch("stop-id");
  });
});

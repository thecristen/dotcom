import React, { ReactElement } from "react";
import MapMarker from "../../app/googleMaps/Marker";
import stopIncludesModes from "../helpers/stop-includes-modes";
import { MarkerData } from "../../app/googleMaps/__googleMaps";
import { Mode } from "../../__v3api";
import { Dispatch } from "../state";
import { StopWithRoutes } from "./__tnm";

interface Props {
  map: google.maps.Map;
  data: MarkerData;
  isSelected: boolean;
  dispatch: Dispatch;
  stopData: StopWithRoutes | undefined;
  shouldFilterMarkers: boolean;
  selectedModes: Mode[];
}

export const isVisible = (
  stopData: StopWithRoutes | undefined,
  shouldFilterMarkers: boolean,
  selectedModes: Mode[]
): boolean =>
  shouldFilterMarkers && stopData
    ? stopIncludesModes(stopData, selectedModes)
    : true;

const Marker = ({
  map,
  data,
  isSelected,
  dispatch,
  stopData,
  shouldFilterMarkers,
  selectedModes
}: Props): ReactElement<HTMLElement> => (
  <MapMarker
    map={map}
    data={{
      ...data,
      "visible?": isVisible(stopData, shouldFilterMarkers, selectedModes)
    }}
    dispatch={dispatch}
    isSelected={isSelected}
  />
);

export default Marker;

import React, { useReducer, ReactElement } from "react";
import TransitNearMeMap from "./TransitNearMeMap";
import RoutesSidebar from "./RoutesSidebar";
import StopsSidebar from "./StopsSidebar";
import { Stop, RouteWithStopsWithDirections, Mode } from "../../__v3api";
import { StopWithRoutes } from "./__tnm";
import { MapData } from "../../app/googleMaps/__googleMaps";
import { reducer, initialState, SelectedStopType, State } from "../state";
import { QueryParams } from "../../helpers/query";

interface Props {
  mapData: MapData;
  mapId: string;
  query: QueryParams;
  routeSidebarData: RouteWithStopsWithDirections[];
  stopSidebarData: StopWithRoutes[];
}

export const getSelectedStop = (
  stopSidebarData: StopWithRoutes[],
  selectedStopId: SelectedStopType
): Stop | undefined => {
  const stopWithRoute = stopSidebarData.find(
    stopWithRoutes => stopWithRoutes.stop.stop.id === selectedStopId
  );
  return stopWithRoute ? stopWithRoute.stop.stop : undefined;
};

const validateModeFilter = (acc: Mode[], mode: string): Mode[] =>
  mode === "subway" || mode === "bus" || mode === "commuter_rail"
    ? acc.concat([mode])
    : acc;

export const modesFromQuery = (query: QueryParams): Mode[] =>
  query.filter ? query.filter.split(",").reduce(validateModeFilter, []) : [];

const TransitNearMe = ({
  mapData,
  mapId,
  routeSidebarData,
  query,
  stopSidebarData
}: Props): ReactElement<HTMLElement> => {
  const modes = modesFromQuery(query);
  const initialStateWithModes: State = {
    ...initialState,
    selectedModes: modes,
    shouldFilterStopCards: modes.length > 0
  };
  const [state, dispatch] = useReducer(reducer, initialStateWithModes);
  const selectedStop = getSelectedStop(stopSidebarData, state.selectedStopId);
  return (
    <div className="m-tnm">
      {state.routesView ? (
        <RoutesSidebar
          selectedStop={selectedStop}
          selectedModes={state.selectedModes}
          selectedStopId={state.selectedStopId}
          dispatch={dispatch}
          data={routeSidebarData}
          shouldFilterStopCards={state.shouldFilterStopCards}
        />
      ) : (
        <StopsSidebar
          selectedStop={selectedStop}
          selectedModes={state.selectedModes}
          selectedStopId={state.selectedStopId}
          dispatch={dispatch}
          data={stopSidebarData}
          shouldFilterStopCards={state.shouldFilterStopCards}
        />
      )}
      <h3 className="sr-only">Map</h3>
      <div
        id={mapId}
        className="m-tnm__map"
        role="application"
        aria-label="Map with stops"
      />
      <TransitNearMeMap
        selectedStopId={state.selectedStopId}
        dispatch={dispatch}
        mapElementId={mapId}
        initialData={mapData}
        selectedModes={state.selectedModes}
        stopData={stopSidebarData}
        shouldFilterMarkers={state.shouldFilterStopCards}
        shouldCenterMapOnSelectedStop={state.shouldCenterMapOnSelectedStop}
      />
    </div>
  );
};

export default TransitNearMe;

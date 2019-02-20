import React, { useReducer, ReactElement } from "react";
import TransitNearMeMap from "./googleMaps/TransitNearMeMap";
import RoutesSidebar from "./RoutesSidebar";
import { Route, Stop, MapData } from "./__tnm";
import { reducer, initialState, SelectedStopType } from "../state";

interface Props {
  mapData: MapData;
  mapId: string;
  sidebarData: Route[];
  getSidebarOffset: () => number;
}

const selectedStop = (
  sidebarData: Route[],
  selectedStopId: SelectedStopType
): Stop | undefined => {
  const stops = sidebarData.reduce(
    (acc, route) => acc.concat(route.stops),
    [] as Stop[]
  );
  return stops.find(stop => stop.id === selectedStopId);
};

const TransitNearMe = ({
  mapData,
  mapId,
  sidebarData,
  getSidebarOffset
}: Props): ReactElement<HTMLElement> => {
  const [state, dispatch] = useReducer(reducer, initialState);

  return (
    <div className="m-tnm">
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
        shouldCenterMapOnSelectedStop={state.shouldCenterMapOnSelectedStop}
      />
      <RoutesSidebar
        selectedStop={selectedStop(sidebarData, state.selectedStopId)}
        selectedStopId={state.selectedStopId}
        dispatch={dispatch}
        data={sidebarData}
        shouldFilterStopCards={state.shouldFilterStopCards}
        getOffset={getSidebarOffset}
      />
    </div>
  );
};

export default TransitNearMe;

import React, { ReactElement } from "react";
import RouteCard from "./RouteCard";
import RouteSidebarHeader from "./RouteSidebarHeader";
import { TNMRoute, TNMStop } from "./__tnm";
import { Dispatch } from "../state";

interface Props {
  data: TNMRoute[];
  dispatch: Dispatch;
  selectedStopId: string | null;
  shouldFilterStopCards: boolean;
  selectedStop: TNMStop | undefined;
}

const filterDataByStopId = (data: TNMRoute[], stopId: string): TNMRoute[] =>
  data.reduce((accumulator: TNMRoute[], route: TNMRoute): TNMRoute[] => {
    const stops = route.stops.filter(stop => stop.id === stopId);
    if (stops.length === 0) {
      return accumulator;
    }
    return accumulator.concat(Object.assign({}, route, { stops }));
  }, []);

export const filterData = (
  data: TNMRoute[],
  selectedStopId: string | null,
  shouldFilter: boolean
): TNMRoute[] => {
  if (shouldFilter === false || selectedStopId === null) {
    return data;
  }

  return filterDataByStopId(data, selectedStopId);
};

const RoutesSidebar = (props: Props): ReactElement<HTMLElement> | null => {
  const {
    data,
    dispatch,
    selectedStopId,
    selectedStop,
    shouldFilterStopCards
  } = props;

  return data.length ? (
    <div className="m-tnm-sidebar">
      <RouteSidebarHeader
        showPill={shouldFilterStopCards}
        selectedStop={selectedStop}
        dispatch={dispatch}
      />
      {filterData(data, selectedStopId, shouldFilterStopCards).map(route => (
        <RouteCard key={route.id} route={route} dispatch={dispatch} />
      ))}
    </div>
  ) : null;
};

export default RoutesSidebar;

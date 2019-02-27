import React, { ReactElement } from "react";
import RouteCard from "./RouteCard";
import RouteSidebarHeader from "./RouteSidebarHeader";
import { Route, Stop } from "./__tnm";
import { Dispatch } from "../state";

interface Props {
  data: Route[];
  dispatch: Dispatch;
  selectedStopId: string | null;
  shouldFilterStopCards: boolean;
  selectedStop: Stop | undefined;
}

const filterDataByStopId = (data: Route[], stopId: string): Route[] =>
  data.reduce((accumulator: Route[], route: Route): Route[] => {
    const stops = route.stops.filter(stop => stop.id === stopId);
    if (stops.length === 0) {
      return accumulator;
    }
    return accumulator.concat(Object.assign({}, route, { stops }));
  }, []);

export const filterData = (
  data: Route[],
  selectedStopId: string | null,
  shouldFilter: boolean
): Route[] => {
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
      <RouteSidebarHeader selectedStop={selectedStop} dispatch={dispatch} />
      {filterData(data, selectedStopId, shouldFilterStopCards).map(route => (
        <RouteCard key={route.id} route={route} dispatch={dispatch} />
      ))}
    </div>
  ) : null;
};

export default RoutesSidebar;

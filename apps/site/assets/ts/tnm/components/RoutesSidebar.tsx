import React, { ReactElement } from "react";
import RouteCard from "./RouteCard";
import RouteSidebarHeader from "./RouteSidebarHeader";
import { ModeFilter, tnmModeByV3ModeType } from "./ModeFilter";
import { TNMMode, TNMRoute, TNMStop } from "./__tnm";
import { Dispatch } from "../state";

interface Props {
  data: TNMRoute[];
  dispatch: Dispatch;
  selectedStopId: string | null;
  shouldFilterStopCards: boolean;
  selectedStop: TNMStop | undefined;
  selectedModes: TNMMode[];
}

interface FilterOptions {
  stopId: string | null;
  modes: TNMMode[];
}

const filterDataByModes = (
  data: TNMRoute[],
  { modes }: FilterOptions
): TNMRoute[] => {
  // if there are no selections or all selections, do not filter
  if (modes.length === 0 || modes.length === 3) {
    return data;
  }
  return data.filter(route =>
    modes.reduce((accumulator: boolean, mode: TNMMode) => {
      if (accumulator === true) {
        return accumulator;
      }
      return tnmModeByV3ModeType[route.type] === mode;
    }, false)
  );
};

const filterDataByStopId = (
  data: TNMRoute[],
  { stopId }: FilterOptions
): TNMRoute[] => {
  if (stopId === null) {
    return data;
  }
  return data.reduce((accumulator: TNMRoute[], route: TNMRoute): TNMRoute[] => {
    const stops = route.stops.filter(stop => stop.id === stopId);
    if (stops.length === 0) {
      return accumulator;
    }
    return accumulator.concat(Object.assign({}, route, { stops }));
  }, []);
};

export const filterData = (
  data: TNMRoute[],
  selectedStopId: string | null,
  selectedModes: TNMMode[],
  shouldFilter: boolean
): TNMRoute[] => {
  if (shouldFilter === false) {
    return data;
  }

  const options: FilterOptions = {
    stopId: selectedStopId,
    modes: selectedModes
  };

  return [filterDataByStopId, filterDataByModes].reduce(
    (accumulator, fn) => fn(accumulator, options),
    data
  );
};

const RoutesSidebar = (props: Props): ReactElement<HTMLElement> | null => {
  const {
    data,
    dispatch,
    selectedModes,
    selectedStopId,
    selectedStop,
    shouldFilterStopCards
  } = props;

  return data.length ? (
    <div className="m-tnm-sidebar">
      <ModeFilter selectedModes={selectedModes} dispatch={dispatch} />
      <RouteSidebarHeader
        selectedStop={selectedStop}
        showPill={shouldFilterStopCards}
        dispatch={dispatch}
      />
      {filterData(
        data,
        selectedStopId,
        selectedModes,
        shouldFilterStopCards
      ).map(route => (
        <RouteCard key={route.id} route={route} dispatch={dispatch} />
      ))}
    </div>
  ) : null;
};

export default RoutesSidebar;

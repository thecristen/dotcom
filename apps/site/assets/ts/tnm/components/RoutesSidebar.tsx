import React, { ReactElement } from "react";
import RouteCard from "./RouteCard";
import RouteSidebarHeader from "./RouteSidebarHeader";
import { modeByV3ModeType } from "../../components/ModeFilter";
import { Dispatch } from "../state";
import { Mode, RouteWithStopsWithDirections, Stop } from "../../__v3api";
import ModeFilterContainer from "./ModeFilterContainer";

interface Props {
  data: RouteWithStopsWithDirections[];
  dispatch: Dispatch;
  selectedStopId: string | null;
  shouldFilterStopCards: boolean;
  selectedStop: Stop | undefined;
  selectedModes: Mode[];
}

interface FilterOptions {
  stopId: string | null;
  modes: Mode[];
}

const filterDataByModes = (
  data: RouteWithStopsWithDirections[],
  { modes }: FilterOptions
): RouteWithStopsWithDirections[] => {
  // if there are no selections or all selections, do not filter
  if (modes.length === 0 || modes.length === 3) {
    return data;
  }
  return data.filter(route =>
    modes.reduce((accumulator: boolean, mode: Mode) => {
      if (accumulator === true) {
        return accumulator;
      }
      return modeByV3ModeType[route.route.type] === mode;
    }, false)
  );
};

const filterDataByStopId = (
  data: RouteWithStopsWithDirections[],
  { stopId }: FilterOptions
): RouteWithStopsWithDirections[] => {
  if (stopId === null) {
    return data;
  }
  return data.reduce(
    (
      accumulator: RouteWithStopsWithDirections[],
      route: RouteWithStopsWithDirections
    ): RouteWithStopsWithDirections[] => {
      // eslint-disable-next-line typescript/camelcase
      const stops = route.stops_with_directions.filter(
        // eslint-disable-next-line typescript/camelcase
        stop_with_directions => stop_with_directions.stop.id === stopId
      );
      if (stops.length === 0) {
        return accumulator;
      }
      return accumulator.concat(Object.assign({}, route, { stops }));
    },
    []
  );
};

export const filterData = (
  data: RouteWithStopsWithDirections[],
  selectedStopId: string | null,
  selectedModes: Mode[],
  shouldFilter: boolean
): RouteWithStopsWithDirections[] => {
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

const RoutesSidebar = ({
  data,
  dispatch,
  selectedModes,
  selectedStopId,
  selectedStop,
  shouldFilterStopCards
}: Props): ReactElement<HTMLElement> | null =>
  data.length ? (
    <div className="m-tnm-sidebar">
      <ModeFilterContainer selectedModes={selectedModes} dispatch={dispatch} />
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
        <RouteCard key={route.route.id} route={route} dispatch={dispatch} />
      ))}
    </div>
  ) : null;

export default RoutesSidebar;

import React, { ReactElement } from "react";
import { StopWithRoutes, TNMStop, TNMMode } from "./__tnm";
import { Dispatch } from "../state";
import { ModeFilter, tnmModeByV3ModeType } from "./ModeFilter";
import SidebarTitle from "./SidebarTitle";
import StopWithRoutesCard from "./StopWithRoutesCard";

interface Props {
  data: StopWithRoutes[];
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

const filterDataByStopId = (
  data: StopWithRoutes[],
  { stopId }: FilterOptions
): StopWithRoutes[] => {
  if (stopId === null) {
    return data;
  }
  const stopWithRoutes = data.find(d => d.stop.id === stopId);
  return stopWithRoutes ? [stopWithRoutes] : data;
};

const filterDataByModes = (
  data: StopWithRoutes[],
  { modes }: FilterOptions
): StopWithRoutes[] => {
  // if there are no selections or all selections, do not filter
  if (modes.length === 0 || modes.length === 3) {
    return data;
  }

  return data.filter(stop =>
    modes.reduce((accumulator: boolean, mode: TNMMode) => {
      if (accumulator === true) {
        return accumulator;
      }
      return stop.routes.some(routeGroup =>
        routeGroup.routes.some(
          subroute => tnmModeByV3ModeType[subroute.type] === mode
        )
      );
    }, false)
  );
};

export const filterData = (
  data: StopWithRoutes[],
  selectedStopId: string | null,
  selectedModes: TNMMode[],
  shouldFilter: boolean
): StopWithRoutes[] => {
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

const StopsSidebar = ({
  dispatch,
  data,
  selectedStopId,
  selectedModes,
  shouldFilterStopCards
}: Props): ReactElement<HTMLElement> | null =>
  data.length ? (
    <div className="m-tnm-sidebar" id="tnm-sidebar-by-stops">
      <ModeFilter selectedModes={selectedModes} dispatch={dispatch} />
      <div className="m-tnm-sidebar__header">
        <SidebarTitle dispatch={dispatch} viewType="Stops" />
      </div>
      <>
        {filterData(
          data,
          selectedStopId,
          selectedModes,
          shouldFilterStopCards
        ).map(({ stop, routes }) => (
          <StopWithRoutesCard
            key={stop.id}
            stop={stop}
            routes={routes}
            dispatch={dispatch}
          />
        ))}
      </>
    </div>
  ) : null;

export default StopsSidebar;

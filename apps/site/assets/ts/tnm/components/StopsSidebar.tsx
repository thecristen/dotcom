import React, { ReactElement } from "react";
import { Mode, Stop } from "../../__v3api";
import { StopWithRoutes } from "./__tnm";
import { Dispatch } from "../state";
import { modeByV3ModeType } from "../../components/ModeFilter";
import SidebarTitle from "./SidebarTitle";
import StopWithRoutesCard from "./StopWithRoutesCard";
import ModeFilterContainer from "./ModeFilterContainer";

interface Props {
  data: StopWithRoutes[];
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

const filterDataByStopId = (
  data: StopWithRoutes[],
  { stopId }: FilterOptions
): StopWithRoutes[] => {
  if (stopId === null) {
    return data;
  }
  const stopWithRoutes = data.find(d => d.stop.stop.id === stopId);
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
    modes.reduce((accumulator: boolean, mode: Mode) => {
      if (accumulator === true) {
        return accumulator;
      }
      return stop.routes.some(routeGroup =>
        routeGroup.routes.some(
          subroute => modeByV3ModeType[subroute.type] === mode
        )
      );
    }, false)
  );
};

export const filterData = (
  data: StopWithRoutes[],
  selectedStopId: string | null,
  selectedModes: Mode[],
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
      <ModeFilterContainer selectedModes={selectedModes} dispatch={dispatch} />
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
            key={stop.stop.id}
            stop={stop.stop}
            routes={routes}
            dispatch={dispatch}
          />
        ))}
      </>
    </div>
  ) : null;

export default StopsSidebar;

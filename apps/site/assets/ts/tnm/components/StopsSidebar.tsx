import React, { ReactElement } from "react";
import { StopWithRoutes, Stop } from "./__tnm";
import { Dispatch } from "../state";
import SidebarTitle from "./SidebarTitle";
import StopWithRoutesCard from "./StopWithRoutesCard";

interface Props {
  data: StopWithRoutes[];
  dispatch: Dispatch;
  selectedStopId: string | null;
  shouldFilterStopCards: boolean;
  selectedStop: Stop | undefined;
}

const filterDataByStopId = (
  data: StopWithRoutes[],
  stopId: string
): StopWithRoutes[] => {
  const stopWithRoutes = data.find(d => d.stop.id === stopId);
  return stopWithRoutes ? [stopWithRoutes] : data;
};

export const filterData = (
  data: StopWithRoutes[],
  selectedStopId: string | null,
  shouldFilter: boolean
): StopWithRoutes[] => {
  if (shouldFilter === false || selectedStopId === null) {
    return data;
  }

  return filterDataByStopId(data, selectedStopId);
};

const StopsSidebar = ({
  dispatch,
  data,
  selectedStopId,
  shouldFilterStopCards
}: Props): ReactElement<HTMLElement> | null =>
  data.length ? (
    <div className="m-tnm-sidebar" id="tnm-sidebar-by-stops">
      <div className="m-tnm-sidebar__header">
        <SidebarTitle dispatch={dispatch} viewType="Stops" />
      </div>
      <>
        {filterData(data, selectedStopId, shouldFilterStopCards).map(
          ({ stop, routes }) => (
            <StopWithRoutesCard
              key={stop.id}
              stop={stop}
              routes={routes}
              dispatch={dispatch}
            />
          )
        )}
      </>
    </div>
  ) : null;

export default StopsSidebar;

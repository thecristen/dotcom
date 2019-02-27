/* eslint-disable react/prefer-stateless-function */
import React, { ReactElement } from "react";
import { StopCard, stopIsEmpty } from "./StopCard";
import { Route, Stop } from "./__tnm";
import { renderSvg } from "./helpers";
// @ts-ignore
import alertIcon from "../../../static/images/icon-alerts-triangle.svg";
import { Dispatch } from "../state";

interface Props {
  route: Route;
  dispatch: Dispatch;
}

const routeIsEmpty = (route: Route): boolean => route.stops.every(stopIsEmpty);

const filterStops = (route: Route): Stop[] => {
  // show the closest two stops for bus, in order to display both inbound and outbound stops

  const count = route.type === 3 ? 2 : 1;
  return route.stops.slice(0, count);
};

export const isSilverLine = (route: Route): boolean => {
  const mapSet: { [routeId: string]: boolean } = {
    "741": true,
    "742": true,
    "743": true,
    "746": true,
    "749": true,
    "751": true
  };

  return mapSet[route.id] || false;
};

export const routeBgColor = (route: Route): string => {
  if (route.type === 2) return "commuter-rail";
  if (route.type === 4) return "ferry";
  if (route.id === "Red") return "red-line";
  if (route.id === "Orange") return "orange-line";
  if (route.id === "Blue") return "blue-line";
  if (route.id.startsWith("Green-")) return "green-line";
  if (isSilverLine(route)) return "silver-line";
  if (route.type === 3) return "bus";
  return "unknown";
};

export const busClass = (route: Route): string =>
  route.type === 3 && !isSilverLine(route) ? "bus-route-sign" : "";

const RouteCard = ({
  route,
  dispatch
}: Props): ReactElement<HTMLElement> | null => {
  const bgClass = `u-bg--${routeBgColor(route)}`;

  if (routeIsEmpty(route)) {
    return null;
  }

  return (
    <div className="m-tnm-sidebar__route">
      <a
        href={`/schedules/${route.id}`}
        className={`h3 m-tnm-sidebar__route-name ${bgClass}`}
      >
        <span className={busClass(route)}>{route.name}</span>
        {route.alert_count
          ? renderSvg("m-tnm-sidebar__route-alert", alertIcon)
          : null}
      </a>
      {filterStops(route).map(stop => (
        <StopCard key={stop.id} stop={stop} route={route} dispatch={dispatch} />
      ))}
    </div>
  );
};

export default RouteCard;

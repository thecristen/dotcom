/* eslint-disable react/prefer-stateless-function */
import React from "react";
import StopCard from "./StopCard";
import { Route } from "./__tnm";

interface Props {
  route: Route;
}

const RouteCard = ({ route }: Props) => {
  const bgClass = `u-bg--${routeBgColor(route)}`;

  return (
    <div className="m-tnm-sidebar__route">
      <div className={`h3 m-tnm-sidebar__route-name ${bgClass}`}>
        <span className={busClass(route)}>{route.name}</span>
      </div>
      {route.stops.map(stop => (
        <StopCard key={stop.id} stop={stop} route={route} />
      ))}
    </div>
  );
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

export default RouteCard;

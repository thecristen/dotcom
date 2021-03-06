import { Route, RouteType } from "../__v3api";

const isRouteType = (obj: Route | RouteType): obj is RouteType =>
  typeof obj === "number";

export const isABusRoute = ({ type }: Route): boolean => type === 3;

const isCommuterRailRouteType = (type: RouteType): boolean => type === 2;

export const isACommuterRailRoute = (routeOrType: Route | RouteType): boolean =>
  isRouteType(routeOrType)
    ? isCommuterRailRouteType(routeOrType)
    : isCommuterRailRouteType(routeOrType.type);

export const isAGreenLineRoute = ({ id }: Route): boolean =>
  id.startsWith("Green");

export const isASilverLineRoute = (routeOrRouteId: Route | string): boolean => {
  const id =
    typeof routeOrRouteId === "string" ? routeOrRouteId : routeOrRouteId.id;
  return ["741", "742", "743", "746", "749", "751"].includes(id);
};

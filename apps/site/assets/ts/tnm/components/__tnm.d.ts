// eslint-disable-next-line typescript/no-unused-vars
import { StopWithDirections, Route } from "../../__v3api";

export type TNMMode = "subway" | "bus" | "rail";

export interface StopWithRoutes {
  stop: StopWithDirections;
  routes: RouteGroup[];
  distance: string;
}

export type RouteGroupName = "commuter_rail" | "subway" | "bus" | "ferry";

export interface RouteGroup {
  group_name: RouteGroupName;
  routes: Route[];
}

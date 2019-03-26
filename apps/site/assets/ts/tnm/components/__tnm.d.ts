// eslint-disable-next-line typescript/no-unused-vars
import { Route, Stop } from "../../__v3api";

export type TNMMode = "subway" | "bus" | "rail";

export interface TNMRoute extends Route {
  stops: TNMStop[];
}

export interface TNMStop extends Stop {
  directions: TNMDirection[];
}

type DirectionId = 0 | 1;

export interface TNMDirection {
  direction_id: DirectionId;
  headsigns: TNMHeadsign[];
}

export interface TNMHeadsign {
  name: string;
  times: TNMTime[];
  train_number: string | null;
}

export interface TNMTime {
  delay: number;
  scheduled_time: string[] | null;
  prediction: TNMPrediction | null;
}

export interface TNMPrediction {
  time: string[];
  status: string | null;
  track: string | null;
}

export interface Trip {
  "bikes_allowed?": true;
  direction_id: 0 | 1;
  headsign: string;
  id: string;
  name: string;
  shape_id: string;
}

export interface Schedule {
  "early_departure?": boolean;
  "flag?": boolean;
  pickup_type: number;
  route: Route;
  stop: TNMStop;
  stop_sequence: number;
  time: string;
  trip: Trip;
}

interface StopWithRoutes {
  distance: string;
  stop: TNMStop;
  routes: RouteGroup[];
}

type RouteGroupName = "commuter_rail" | "subway" | "bus" | "ferry";

interface RouteGroup {
  group_name: RouteGroupName;
  routes: TNMRoute[];
}

// eslint-disable-next-line typescript/no-unused-vars
import { Route, Stop } from "../../v3api";

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

interface LatLng {
  latitude: number;
  longitude: number;
}

interface Label {
  color: string | null;
  font_family: string | null;
  font_size: string | null;
  font_weight: string | null;
  text: string | null;
}

interface MarkerData {
  id: string;
  latitude: number;
  longitude: number;
  icon: string | null;
  "visible?": boolean;
  size: string;
  tooltip: string | null;
  z_index: number;
  label: Label | null;
}

interface Path {
  polyline: string;
  color: string;
  weight: number;
  "dotted?": boolean;
}

interface Layers {
  transit: boolean;
}

interface Padding {
  left: number;
  right: number;
  top: number;
  bottom: number;
}

export interface MapData {
  default_center: LatLng;
  markers: MarkerData[];
  paths: Path[];
  width: number;
  height: number;
  zoom: number | null;
  scale: 1 | 2;
  dynamic_options: google.maps.MapOptions;
  layers: Layers;
  auto_init: boolean;
  reset_bounds_on_update: boolean;
  bound_padding: Padding | null;
}

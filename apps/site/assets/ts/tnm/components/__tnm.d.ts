export interface DirectionInfo {
  0: string;
  1: string;
}

export interface Route {
  alert_count: number;
  description: string;
  direction_destinations: DirectionInfo;
  direction_names: DirectionInfo;
  id: string;
  long_name: string;
  name: string;
  type: RouteType;
  stops: Stop[];
  href?: string;
}

export interface Stop {
  accessibility: string[];
  address: string | null;
  closed_stop_info: string | null;
  "has_charlie_card_vendor?": boolean;
  "has_fare_machine?": boolean;
  id: string;
  "is_child?": boolean;
  latitude: number;
  longitude: number;
  name: string;
  note: string | null;
  parking_lots: ParkingLot[];
  "station?": boolean;
  distance: string;
  directions: TNMDirection[];
  href: string;
}

interface ParkingLot {
  name: string;
  address: string;
  capacity?: {
    total?: number;
    accessible?: number;
    type?: string;
  };
  payment?: {
    methods: string[];
    mobile_app?: {
      name?: string;
      id?: string;
      url?: string;
    };
    daily_rate?: string;
    monthly_rate?: string;
  };
  manager?: {
    name?: string;
    contact?: string;
    phone?: string;
    url?: string;
  };
  utilization?: {
    arrive_before?: string;
    typical?: number;
  };
  note?: string;
  latitude?: number;
  longitude?: number;
}

type DirectionId = 0 | 1;

type RouteType = 0 | 1 | 2 | 3 | 4;

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
  scheduled_time: string[] | null;
  prediction: TNMPrediction | null;
}

export interface TNMPrediction {
  time: string[];
  status: string;
  track: string;
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
  stop: Stop;
  stop_sequence: number;
  time: string;
  trip: Trip;
}

interface StopWithRoutes {
  distance: string;
  stop: Stop;
  routes: RouteGroup[];
}

type RouteGroupName = "commuter_rail" | "subway" | "bus" | "ferry";

interface RouteGroup {
  group_name: RouteGroupName;
  routes: Route[];
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

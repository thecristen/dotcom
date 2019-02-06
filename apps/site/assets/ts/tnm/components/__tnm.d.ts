export interface DirectionInfo {
  0: string;
  1: string;
}

export interface SVGMarkers {
  stopMarker: string;
  stationMarker: string;
}

export interface Route {
  description: string;
  direction_destinations: DirectionInfo;
  direction_names: DirectionInfo;
  id: string;
  long_name: string;
  name: string;
  type: number;
  stops: Array<Stop>;
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
  parking_lots: any[];
  "station?": boolean;
  distance: string;
  directions: Array<TNMDirection>;
  href: string;
}

type DirectionId = 0 | 1;

export interface TNMDirection {
  direction_id: DirectionId;
  headsigns: Array<TNMHeadsign>;
}

export interface TNMHeadsign {
  name: string;
  times: Array<TNMTime>;
}

export interface TNMTime {
  schedule: Array<string>;
  prediction: TNMPrediction | null;
}

export interface TNMPrediction {
  time: Array<string>;
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

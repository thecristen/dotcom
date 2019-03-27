export interface Direction {
  direction_id: DirectionId;
  headsigns: Headsign[];
}

type DirectionId = 0 | 1;

interface DirectionInfo {
  0: string;
  1: string;
}

export interface Headsign {
  name: string;
  times: PredictedOrScheduledTime[];
  train_number: string | null;
}

export interface ParkingLot {
  name: string;
  address: string | null;
  capacity: ParkingLotCapacity | null;
  payment: ParkingLotPayment | null;
  manager: ParkingLotManager | null;
  utilization?: ParkingLotUtilization | null;
  note?: string | null;
  latitude?: number;
  longitude?: number;
}

export interface ParkingLotCapacity {
  total?: number;
  accessible?: number;
  type?: string;
}

export interface ParkingLotManager {
  name?: string;
  contact?: string;
  phone: string | null;
  url: string | null;
}

export interface ParkingLotMobileApp {
  name?: string;
  id?: string;
  url: string | null;
}

export interface ParkingLotPayment {
  methods: string[];
  mobile_app?: ParkingLotMobileApp | null;
  daily_rate?: string;
  monthly_rate?: string;
}

export interface ParkingLotUtilization {
  arrive_before?: string;
  typical?: number;
}

export interface PredictedOrScheduledTime {
  delay: number;
  scheduled_time: string[] | null;
  prediction: Prediction | null;
}

export interface Prediction {
  time: string[];
  status: string | null;
  track: string | null;
}

export interface Route {
  alert_count: number;
  description: string;
  direction_destinations: DirectionInfo;
  direction_names: DirectionInfo;
  header: string;
  id: string;
  long_name: string;
  name: string;
  type: RouteType;
  href?: string;
}

export interface RouteWithStopsWithDirections {
  route: Route;
  stops_with_directions: StopWithDirections[];
}

export type RouteType = 0 | 1 | 2 | 3 | 4;

export type BikeStorageType =
  | "bike_storage_rack"
  | "bike_storage_rack_covered"
  | "bike_storage_cage";

export type FareFacilityType =
  | "fare_vending_retailer"
  | "fare_vending_machine"
  | "fare_media_assistant"
  | "fare_media_assistance_facility"
  | "ticket_window";

export type AccessibilityType =
  | "tty_phone"
  | "escalator_both"
  | "escalator_up"
  | "escalator_down"
  | "ramp"
  | "fully_elevated_platform"
  | "elevated_subplatform"
  | "unknown"
  | "accessibile"
  | "elevator"
  | "portable_boarding_lift"
  | string;

export interface Stop {
  accessibility: AccessibilityType[];
  address: string | null;
  bike_storage: BikeStorageType[];
  closed_stop_info: string | null;
  "has_charlie_card_vendor?": boolean;
  "has_fare_machine?": boolean;
  fare_facilities: FareFacilityType[];
  id: string;
  "is_child?": boolean;
  latitude: number;
  longitude: number;
  name: string;
  note: string | null;
  parking_lots: ParkingLot[];
  "station?": boolean;
  distance?: string;
  href?: string;
}

export interface StopWithDirections {
  stop: Stop;
  directions: Direction[];
}

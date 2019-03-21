interface DirectionInfo {
  0: string;
  1: string;
}

export interface ParkingLotCapacity {
  total?: number;
  accessible?: number;
  type?: string;
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

export interface ParkingLotManager {
  name?: string;
  contact?: string;
  phone: string | null;
  url: string | null;
}

export interface ParkingLotUtilization {
  arrive_before?: string;
  typical?: number;
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
  stops: Stop[];
  href?: string;
}

export type RouteType = 0 | 1 | 2 | 3 | 4;

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
  distance?: string;
  href?: string;
}

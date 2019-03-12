interface DirectionInfo {
  0: string;
  1: string;
}

export interface ParkingLot {
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
  distance: string;
  href: string;
}

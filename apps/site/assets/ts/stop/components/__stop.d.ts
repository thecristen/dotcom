import { Direction, DirectionId, Route, Stop, Alert } from "../../__v3api";
import { MapData } from "../../leaflet/components/__mapdata";

export interface TypedRoutes {
  group_name: string;
  routes: RouteWithDirections[];
}

export interface StopMapData {
  map_data: MapData;
  map_srcset: string;
  map_url: string;
}

export interface RouteWithDirection {
  direction_id: DirectionId | null;
  route: Route;
}

export interface SuggestedTransfer {
  stop: Stop;
  distance: number;
  routes_with_direction: RouteWithDirection[];
}

export interface StopPageData {
  stop: Stop;
  street_view_url: string | null;
  routes: TypedRoutes[];
  suggested_transfers: SuggestedTransfer[];
  tabs: Tab[];
  zone_number: string;
  retail_locations: RetailLocationWithDistance[];
  alerts: Alert[];
}

export interface Tab {
  badge?: TabBadge;
  class: string;
  href: string;
  id: string;
  name: string;
}

export interface TabBadge {
  content: string;
  aria_label: string;
  class?: string;
}

export interface RetailLocation {
  address: string;
  latitude: number;
  longitude: number;
  name: string;
  payment: string[];
  phone: string;
}

export interface RetailLocationWithDistance {
  distance: string;
  location: RetailLocation;
}

export interface RouteWithDirections {
  route: Route;
  directions: Direction[];
}

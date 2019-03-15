import { Stop, Route } from "../../v3api";
import { MapData } from "../../app/googleMaps/__googleMaps";

export interface TypedRoutes {
  group_name: string;
  routes: Route[];
}

export interface StopMapData {
  map_data: MapData;
  map_srcset: string;
  map_url: string;
}

export interface StopPageData {
  stop: Stop;
  routes: TypedRoutes[];
  tabs: Tab[];
  zone_number: string;
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

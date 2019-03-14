import { Stop } from "../../v3api";
import { MapData } from "../../app/googleMaps/__googleMaps";

export interface StopPageData {
  stop: Stop;
}

export interface StopMapData {
  map_data: MapData;
  map_srcset: string;
  map_url: string;
}

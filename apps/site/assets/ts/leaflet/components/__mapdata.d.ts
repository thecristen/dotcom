import { ReactElement } from "react";

export type TileServerUrl =
  | "https://cdn.mbta.com"
  | "https://mbta-map-tiles-dev.s3.amazonaws.com"
  | "";

export interface MapMarker {
  z_index: number;
  "visible?": boolean;
  tooltip: ReactElement<HTMLElement> | null;
  size: string;
  longitude: number;
  latitude: number;
  id: string | null;
  icon: string | null;
  onClick?: Function;
}

export interface MapData {
  zoom: number;
  width: number;
  markers: MapMarker[];
  height: number;
  tile_server_url: TileServerUrl;
  default_center: {
    longitude: number;
    latitude: number;
  };
}

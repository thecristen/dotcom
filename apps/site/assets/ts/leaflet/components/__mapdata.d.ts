import { ReactElement } from "react";

export type TileServerUrl =
  | "https://cdn.mbta.com"
  | "https://mbta-map-tiles-dev.s3.amazonaws.com"
  | "";

export interface MapMarker {
  icon: string | null;
  id: string | null;
  longitude: number;
  latitude: number;
  onClick?: Function;
  size: string;
  tooltip: ReactElement<HTMLElement> | null;
  "visible?": boolean;
  z_index: number;
}

export interface Polyline {
  color: string;
  "dotted?": boolean;
  id: string;
  positions: [number, number][];
  weight: number;
}

export interface MapData {
  default_center: {
    longitude: number;
    latitude: number;
  };
  height: number;
  markers: MapMarker[];
  polylines: Polyline[];
  tile_server_url: TileServerUrl;
  width: number;
  zoom: number;
}

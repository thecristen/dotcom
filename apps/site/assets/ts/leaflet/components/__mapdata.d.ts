export type TileServerUrl =
  | "http://tile-server.mbtace.com"
  | "http://dev.tile-server.mbtace.com";

export interface MapMarker {
  z_index: number;
  "visible?": boolean;
  tooltip: string | null;
  size: string;
  longitude: number;
  latitude: number;
  label: string | null;
  id: string | null;
  icon: string | null;
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

export interface MapData {
  default_center: LatLng;
  markers: MarkerData[];
  paths: Path[];
  width: number;
  height: number;
  zoom: number | null;
  scale: 1 | 2;
  dynamic_options: google.maps.MapOptions;
  layers: Layers;
  auto_init: boolean;
  reset_bounds_on_update: boolean;
  bound_padding: Padding | null;
}

export interface LatLng {
  latitude: number;
  longitude: number;
}

export interface Label {
  color: string | null;
  font_family: string | null;
  font_size: string | null;
  font_weight: string | null;
  text: string | null;
}

export interface MarkerData {
  id: string;
  latitude: number;
  longitude: number;
  icon: string | null;
  "visible?": boolean;
  size: string;
  tooltip: string | null;
  z_index: number;
  label: Label | null;
}

export interface Path {
  polyline: string;
  color: string;
  weight: number;
  "dotted?": boolean;
}

export interface Layers {
  transit: boolean;
}

export interface Padding {
  left: number;
  right: number;
  top: number;
  bottom: number;
}

import { Icon } from "leaflet";

export default (icon: string): Icon =>
  new Icon({
    iconUrl: `/images/icon-${icon}.svg`,
    iconRetinaUrl: `/images/icon-${icon}.svg`,
    popupAnchor: [0, -25],
    iconSize: [45, 75],
    iconAnchor: [22, 55]
  });

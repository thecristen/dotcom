import { Icon } from "leaflet";

export type IconType = (icon: string | null) => Icon | undefined;

export default (icon: string | null): Icon | undefined =>
  icon === null
    ? undefined
    : new Icon({
        iconUrl: `/images/icon-${icon}.svg`,
        iconRetinaUrl: `/images/icon-${icon}.svg`,
        popupAnchor: [0, -37],
        iconSize: [45, 75],
        iconAnchor: [22, 55]
      });

import { Icon } from "leaflet";
import { IconOpts } from "../leaflet/components/__mapdata";

export default (
  icon: string | null,
  opts: IconOpts = {
    iconAnchor: [22, 55],
    iconSize: [45, 75],
    popupAnchor: [0, -37]
  }
): Icon | undefined =>
  icon === null
    ? undefined
    : new Icon({
        ...opts,
        iconUrl: `/images/icon-${icon}.svg`,
        iconRetinaUrl: `/images/icon-${icon}.svg`
      });

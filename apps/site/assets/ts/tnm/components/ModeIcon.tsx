import React, { ReactElement } from "react";
// @ts-ignore
import GreenLineIconSmall from "../../../static/images/icon-green-line-small.svg";
// @ts-ignore
import RedLineIconSmall from "../../../static/images/icon-red-line-small.svg";
// @ts-ignore
import OrangeLineIconSmall from "../../../static/images/icon-orange-line-small.svg";
// @ts-ignore
import BlueLineIconSmall from "../../../static/images/icon-blue-line-small.svg";
// @ts-ignore
import CommuterRailIconSmall from "../../../static/images/icon-mode-commuter-rail-small.svg";
// @ts-ignore
import BusIconSmall from "../../../static/images/icon-mode-bus-small.svg";
// @ts-ignore
import FerryIconSmall from "../../../static/images/icon-mode-ferry-small.svg";
// @ts-ignore
import StationSmall from "../../../static/images/icon-circle-t-small.svg";
// @ts-ignore
import SubwaySmall from "../../../static/images/icon-mode-subway-small.svg";

interface Props {
  type: string;
}

const icons = {
  "green_line-small": GreenLineIconSmall,
  "red_line-small": RedLineIconSmall,
  "orange_line-small": OrangeLineIconSmall,
  "blue_line-small": BlueLineIconSmall,
  "commuter_rail-small": CommuterRailIconSmall,
  "bus-small": BusIconSmall,
  "ferry-small": FerryIconSmall,
  "subway-small": SubwaySmall
};

const ModeIcon = ({ type }: Props): ReactElement<HTMLElement> => {
  // @ts-ignore
  const icon = icons[`${type}-small`] || StationSmall;

  return (
    <span
      className="m-tnm-sidebar__mode-icon"
      // eslint-disable-next-line react/no-danger
      dangerouslySetInnerHTML={{ __html: icon }}
    />
  );
};

export default ModeIcon;

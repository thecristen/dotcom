import React, { ReactElement } from "react";
import ExpandableBlock from "../../app/ExpandableBlock";
import RoutePillList from "./RoutePillList";
import Fares from "./sidebar/Fares";
// @ts-ignore
import accessibleIcon from "../../../static/images/icon-accessible-default.svg";
import ParkingInfo from "./ParkingInfo";
import BikeStorageInfo from "./BikeStorageInfo";
import { Stop } from "../../__v3api";
import { TypedRoutes, RetailLocationWithDistance } from "./__stop";

interface Props {
  stop: Stop;
  routes: TypedRoutes[];
  retailLocations: RetailLocationWithDistance[];
}

const Sidebar = ({
  stop,
  routes,
  retailLocations
}: Props): ReactElement<HTMLElement> => (
  <>
    <div className="m-stop-page__sidebar-pills">
      <RoutePillList routes={routes} />
    </div>
    <h2>Features</h2>
    <ExpandableBlock
      initiallyExpanded={false}
      id="accessibility"
      header={{
        text: "Accessibility",
        iconSvgText: accessibleIcon
      }}
    >
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html:
            "<p>South Station is accessible. It has the following features:</p><p>This is a test</p>"
        }}
      />
    </ExpandableBlock>
    <ParkingInfo stop={stop} />
    <BikeStorageInfo stop={stop} />
    <Fares stop={stop} retailLocations={retailLocations} />
  </>
);

export default Sidebar;

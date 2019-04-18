import React, { ReactElement } from "react";
import RoutePillList from "./RoutePillList";
import Accessibility from "./sidebar/Accessibility";
import Parking from "./sidebar/Parking";
import BikeStorage from "./sidebar/BikeStorage";
import Fares from "./sidebar/Fares";
import { Stop } from "../../__v3api";
import { TypedRoutes, RetailLocationWithDistance } from "./__stop";
import Feedback from "../../components/Feedback";

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
    <Accessibility stop={stop} routes={routes} />
    <Parking stop={stop} />
    <BikeStorage stop={stop} />
    <Fares stop={stop} retailLocations={retailLocations} />
    <Feedback />
  </>
);

export default Sidebar;

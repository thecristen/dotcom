import React, { ReactElement } from "react";
import icon from "../../../static/images/icon-schedule-finder.svg";
import ExpandableBlock from "../../components/ExpandableBlock";
import ScheduleFinder from "./ScheduleFinder";
import {
  DirectionId,
  EnhancedRoute,
  ServiceWithServiceDate
} from "../../__v3api";
import { Holiday, SimpleStopMap, RoutePatternsByDirection } from "./__schedule";

interface Props {
  directionId: DirectionId;
  route: EnhancedRoute;
  stops: SimpleStopMap;
  services: ServiceWithServiceDate[];
  routePatternsByDirection: RoutePatternsByDirection;
  holidays: Holiday[];
}

const ScheduleFinderAccordion = ({
  directionId,
  route,
  stops,
  services,
  routePatternsByDirection,
  holidays
}: Props): ReactElement<HTMLDivElement> => (
  <div className="schedule-finder--mobile">
    <ExpandableBlock
      header={{ text: "Schedule Finder", iconSvgText: icon }}
      initiallyExpanded={false}
      id="schedule-finder-mobile"
      panelClassName="schedule-finder--accordion"
    >
      <ScheduleFinder
        directionId={directionId}
        hideHeader
        route={route}
        stops={stops}
        services={services}
        routePatternsByDirection={routePatternsByDirection}
        holidays={holidays}
      />
    </ExpandableBlock>
  </div>
);

export default ScheduleFinderAccordion;

import React, { ReactElement } from "react";
import ScheduleDirection from "./ScheduleDirection";
import { SchedulePageData } from "./__schedule";

export interface SchedulePageDataWithStopListContent extends SchedulePageData {
  stop_list_html: string;
}

const ScheduleDirectionAndStops = (schedulePageData: SchedulePageDataWithStopListContent): ReactElement<HTMLElement> => (
  <>
    <ScheduleDirection
      directionId={schedulePageData.direction_id}
      route={schedulePageData.route}
      shapesById={schedulePageData.shape_map}
      routePatternsByDirection={schedulePageData.route_patterns}
    />
    <div dangerouslySetInnerHTML={{__html: schedulePageData.stop_list_html}} />
  </>
)

export default ScheduleDirectionAndStops;

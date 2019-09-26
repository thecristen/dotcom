import React, { ReactElement, useState } from "react";
import ScheduleDirection from "./ScheduleDirection";
import { SchedulePageData } from "./__schedule";
import { DirectionId } from "../../__v3api";

export interface SchedulePageDataWithStopListContent extends SchedulePageData {
  stop_list_html: string;
}

const ScheduleDirectionAndStops = (schedulePageData: SchedulePageDataWithStopListContent): ReactElement<HTMLElement> => {
  const [stopListHtml, updateStopListHtml] = useState(schedulePageData.stop_list_html);

  return (
    <>
      <ScheduleDirection
        directionId={schedulePageData.direction_id}
        route={schedulePageData.route}
        shapesById={schedulePageData.shape_map}
        routePatternsByDirection={schedulePageData.route_patterns}
      />
      <div dangerouslySetInnerHTML={{__html: stopListHtml}} />
    </>
  );
}

export default ScheduleDirectionAndStops;

import React, { ReactElement, useReducer, useState } from "react";
import ScheduleDirection from "./ScheduleDirection";
import { SchedulePageData } from "./__schedule";
import { DirectionId } from "../../__v3api";
import { reducer } from "./direction/reducer";

export interface SchedulePageDataWithStopListContent extends SchedulePageData {
  stop_list_html: string;
}

const ScheduleDirectionAndStops = (schedulePageData: SchedulePageDataWithStopListContent): ReactElement<HTMLElement> => {
  const {
    direction_id: directionId,
    route,
    shape_map: shapesById,
    route_patterns: routePatternsByDirection,
  } = schedulePageData;

  const defaultRoutePattern = routePatternsByDirection[directionId].slice(
    0,
    1
  )[0];

  const [stopListHtml, updateStopListHtml] = useState(schedulePageData.stop_list_html);
  const [state, dispatch] = useReducer(reducer, {
    routePattern: defaultRoutePattern,
    shape: shapesById[defaultRoutePattern.shape_id],
    directionId,
    shapesById,
    routePatternsByDirection,
    routePatternMenuOpen: false,
    routePatternMenuAll: false,
    itemFocus: null
  });


  return (
    <>
      <ScheduleDirection
        directionId={schedulePageData.direction_id}
        route={schedulePageData.route}
        shapesById={schedulePageData.shape_map}
        routePatternsByDirection={schedulePageData.route_patterns}
        state={state}
        dispatch={dispatch}
      />
      <div dangerouslySetInnerHTML={{__html: stopListHtml}} />
    </>
  );
}

export default ScheduleDirectionAndStops;

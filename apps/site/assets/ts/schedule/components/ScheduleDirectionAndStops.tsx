import React, { ReactElement, useEffect, useReducer } from "react";
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
    stop_list_html: stopListHtml
  } = schedulePageData;

  const defaultRoutePattern = routePatternsByDirection[directionId].slice(
    0,
    1
  )[0];

  const [state, dispatch] = useReducer(reducer, {
    routePattern: defaultRoutePattern,
    shape: shapesById[defaultRoutePattern.shape_id],
    directionId,
    shapesById,
    routePatternsByDirection,
    routePatternMenuOpen: false,
    routePatternMenuAll: false,
    itemFocus: null,
    routeId: route.id,
    stopListHtml,
    firstStopListRender: true
  });

  useEffect(
    () => {
      if(state.firstStopListRender) {
        dispatch({event: "firstStopListRender"});
      } else {
        const stopListUrl = `/schedules/${state.routeId}/line/diagram?direction_id=${state.directionId}`;
        window
          .fetch(stopListUrl)
          .then((response: Response) => {
            if (response.ok) return response.text();
            throw new Error(response.statusText);
          })
          .then((newStopListHtml: string) => {
            dispatch({
              event: "newStopListHtml",
              payload: { newStopListHtml: newStopListHtml }
            });
          });
      }
    },
    [state.directionId]
  );

  return (
    <>
      <ScheduleDirection
        route={schedulePageData.route}
        state={state}
        dispatch={dispatch}
      />
      <div dangerouslySetInnerHTML={{__html: state.stopListHtml }} />
    </>
  );
}

export default ScheduleDirectionAndStops;

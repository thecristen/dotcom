import React, { Dispatch, ReactElement } from "react";
import { DirectionId, EnhancedRoute } from "../../__v3api";
import { ShapesById, RoutePatternsByDirection } from "./__schedule";
import ScheduleDirectionMenu from "./direction/ScheduleDirectionMenu";
import ScheduleDirectionButton from "./direction/ScheduleDirectionButton";
import { Action, State } from "./direction/reducer";

export interface Props {
  route: EnhancedRoute;
  directionId: DirectionId;
  shapesById: ShapesById;
  routePatternsByDirection: RoutePatternsByDirection;
  state: State;
  dispatch: Dispatch<Action>;
}

const ScheduleDirection = ({
  route,
  directionId,
  shapesById,
  routePatternsByDirection,
  state,
  dispatch
}: Props): ReactElement<HTMLElement> => {
  return (
    <div className="m-schedule-direction">
      <div id="direction-name" className="m-schedule-direction__direction">
        {route.direction_names[state.directionId]}
      </div>
      <ScheduleDirectionMenu
        route={route}
        directionId={state.directionId}
        routePatternsByDirection={routePatternsByDirection}
        selectedRoutePatternId={state.routePattern.id}
        menuOpen={state.routePatternMenuOpen}
        showAllRoutePatterns={state.routePatternMenuAll}
        itemFocus={state.itemFocus}
        dispatch={dispatch}
      />
      <ScheduleDirectionButton dispatch={dispatch} />
    </div>
  );
};

export default ScheduleDirection;

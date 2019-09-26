import { DirectionId, Shape } from "../../../__v3api";
import {
  ShapesById,
  RoutePatternsByDirection,
  EnhancedRoutePattern
} from "../__schedule";

export interface State {
  routePattern: EnhancedRoutePattern;
  shape: Shape;
  directionId: DirectionId;
  shapesById: ShapesById;
  routeId: string;
  routePatternsByDirection: RoutePatternsByDirection;
  routePatternMenuOpen: boolean;
  routePatternMenuAll: boolean;
  itemFocus: string | null;
  stopListHtml: string;
  firstStopListRender: boolean;
}

export interface Payload {
  routePattern?: EnhancedRoutePattern;
  newStopListHtml?: string;
}

export interface Action {
  event:
    | "toggleDirection"
    | "setRoutePattern"
    | "toggleRoutePatternMenu"
    | "closeRoutePatternMenu"
    | "showAllRoutePatterns"
    | "firstStopListRender"
    | "newStopListHtml";
  payload?: Payload;
}

const toggleDirection = (state: State): State => {
  const nextDirection = state.directionId === 0 ? 1 : 0;
  const [defaultRoutePatternForDirection] = state.routePatternsByDirection[
    nextDirection
  ];

  return {
    ...state,
    directionId: nextDirection,
    routePattern: defaultRoutePatternForDirection,
    shape: state.shapesById[defaultRoutePatternForDirection.shape_id],
    itemFocus: "first"
  };
};

const toggleRoutePatternMenu = (state: State): State => ({
  ...state,
  routePatternMenuOpen: !state.routePatternMenuOpen,
  itemFocus: "first"
});

const showAllRoutePatterns = (state: State): State => ({
  ...state,
  routePatternMenuAll: true,
  itemFocus: "first-uncommon"
});

export const reducer = (state: State, action: Action): State => {
  switch (action.event) {
    case "toggleDirection":
      return toggleDirection(state);

    case "toggleRoutePatternMenu":
      return toggleRoutePatternMenu(state);

    case "showAllRoutePatterns":
      return showAllRoutePatterns(state);

    case "closeRoutePatternMenu":
      return {
        ...state,
        routePatternMenuOpen: false,
        itemFocus: null
      };

    case "setRoutePattern":
      return {
        ...state,
        routePattern: action.payload!.routePattern!,
        shape: state.shapesById[action.payload!.routePattern!.shape_id],
        routePatternMenuOpen: false,
        itemFocus: null
      };

    case "firstStopListRender":
      return { ...state, firstStopListRender: false };

    case "newStopListHtml":
      return { ...state, stopListHtml: action.payload!.newStopListHtml! };

    /* istanbul ignore next */
    default:
      return state;
  }
};

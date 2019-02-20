export type SelectedStopType = string | null;

interface State {
  selectedStopId: SelectedStopType;
  shouldFilterStopCards: boolean;
  shouldCenterMapOnSelectedStop: boolean;
}

type ActionType =
  | "CLICK_MARKER"
  | "CLICK_CURRENT_LOCATION_MARKER"
  | "CLICK_STOP_CARD"
  | "CLICK_STOP_PILL";

interface Action {
  type: ActionType;
  payload: {
    stopId: SelectedStopType;
  };
}

export const clickMarkerAction = (stopId: SelectedStopType): Action => ({
  type: "CLICK_MARKER",
  payload: { stopId }
});

export const clickCurrentLocationAction = (
  stopId: SelectedStopType
): Action => ({
  type: "CLICK_CURRENT_LOCATION_MARKER",
  payload: { stopId }
});

export const clickStopCardAction = (stopId: SelectedStopType): Action => ({
  type: "CLICK_STOP_CARD",
  payload: { stopId }
});

export const clickStopPillAction = (): Action => ({
  type: "CLICK_STOP_PILL",
  payload: { stopId: null }
});

export const reducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "CLICK_CURRENT_LOCATION_MARKER":
    case "CLICK_MARKER": {
      const target =
        state.selectedStopId === action.payload.stopId
          ? null
          : action.payload.stopId;

      return {
        selectedStopId: target,
        shouldFilterStopCards: !!target && action.type === "CLICK_MARKER",
        shouldCenterMapOnSelectedStop: false
      };
    }
    case "CLICK_STOP_CARD":
      return {
        selectedStopId: action.payload.stopId,
        shouldFilterStopCards: state.shouldFilterStopCards,
        shouldCenterMapOnSelectedStop: true
      };
    case "CLICK_STOP_PILL":
      return {
        selectedStopId: null,
        shouldFilterStopCards: false,
        shouldCenterMapOnSelectedStop: false
      };
    default:
      return state;
  }
};

export const initialState: State = {
  selectedStopId: null,
  shouldFilterStopCards: false,
  shouldCenterMapOnSelectedStop: false
};

export type SelectedStopType = string | null;
export type Dispatch = (action: Action) => void;

interface State {
  selectedStopId: SelectedStopType;
}
type ActionType = "CLICK_MARKER";

export interface Action {
  type: ActionType;
  payload: {
    stopId: SelectedStopType;
  };
}

export const clickMarkerAction = (stopId: SelectedStopType): Action => ({
  type: "CLICK_MARKER",
  payload: { stopId }
});

export const reducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "CLICK_MARKER": {
      const target =
        state.selectedStopId === action.payload.stopId
          ? null
          : action.payload.stopId;

      return {
        selectedStopId: target
      };
    }
    default:
      return state;
  }
};

export const initialState: State = {
  selectedStopId: null
};

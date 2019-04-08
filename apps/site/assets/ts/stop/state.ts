import { Mode } from "../__v3api";

export type SelectedStopType = string | null;
export type Dispatch = (action: Action) => void;

export interface State {
  selectedStopId: SelectedStopType;
  selectedModes: Mode[];
  shouldFilterStopCards: boolean;
}

type StopActionType = "CLICK_MARKER";
type ModeActionType = "CLICK_MODE_FILTER";

export interface StopAction {
  type: StopActionType;
  payload: {
    stopId: SelectedStopType;
  };
}

export interface ModeAction {
  type: ModeActionType;
  payload: {
    mode: Mode;
  };
}

type Action = StopAction | ModeAction;

export const clickMarkerAction = (stopId: SelectedStopType): StopAction => ({
  type: "CLICK_MARKER",
  payload: { stopId }
});

export const clickModeAction = (mode: Mode): ModeAction => ({
  type: "CLICK_MODE_FILTER",
  payload: { mode }
});

const stopReducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "CLICK_MARKER": {
      const target =
        state.selectedStopId === action.payload.stopId
          ? null
          : action.payload.stopId;

      return {
        ...state,
        selectedStopId: target,
        shouldFilterStopCards: !!target
      };
    }
    default:
      return state;
  }
};

const updateModes = (selectedModes: Mode[], mode: Mode): Mode[] =>
  selectedModes.includes(mode)
    ? selectedModes.filter(existingMode => !(existingMode === mode))
    : [...selectedModes, mode];

const modeReducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "CLICK_MODE_FILTER":
      return {
        ...state,
        selectedModes: updateModes(state.selectedModes, action.payload.mode),
        shouldFilterStopCards: true
      };
    default:
      return state;
  }
};

export const reducer = (state: State, action: Action): State =>
  [stopReducer, modeReducer].reduce((acc, fn) => fn(acc, action), state);

export const initialState: State = {
  selectedStopId: null,
  selectedModes: [],
  shouldFilterStopCards: false
};

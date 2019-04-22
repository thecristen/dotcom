import { Mode } from "../__v3api";

export type SelectedStopType = string | null;
export type SelectedTabType = string;
export type Dispatch = (action: Action) => void;

export interface State {
  selectedStopId: SelectedStopType;
  selectedModes: Mode[];
  shouldFilterStopCards: boolean;
  selectedTab: string;
}

type StopActionType = "CLICK_MARKER";
type ModeActionType = "CLICK_MODE_FILTER";
type RoutePillActionType = "CLICK_ROUTE_PILL";
type TabActionType = "SWITCH_TAB";

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

export interface RoutePillAction {
  type: RoutePillActionType;
  payload: {
    mode: Mode;
  };
}

export interface TabAction {
  type: TabActionType;
  payload: {
    tab: SelectedTabType;
  };
}

type Action = StopAction | ModeAction | RoutePillAction | TabAction;

export const clickMarkerAction = (stopId: SelectedStopType): StopAction => ({
  type: "CLICK_MARKER",
  payload: { stopId }
});

export const clickModeAction = (mode: Mode): ModeAction => ({
  type: "CLICK_MODE_FILTER",
  payload: { mode }
});

export const clickRoutePillAction = (mode: Mode): RoutePillAction => ({
  type: "CLICK_ROUTE_PILL",
  payload: { mode }
});

export const clickTabAction = (tab: string): TabAction => ({
  type: "SWITCH_TAB",
  payload: { tab }
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
        selectedTab: "info",
        selectedModes: updateModes(state.selectedModes, action.payload.mode),
        shouldFilterStopCards: true
      };

    case "CLICK_ROUTE_PILL":
      return {
        ...state,
        selectedTab: "info",
        selectedModes: [action.payload.mode],
        shouldFilterStopCards: true
      };

    default:
      return state;
  }
};

const tabReducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "SWITCH_TAB":
      return {
        ...state,
        selectedTab: action.payload.tab
      };
    default:
      return state;
  }
};

export const reducer = (state: State, action: Action): State =>
  [tabReducer, stopReducer, modeReducer].reduce(
    (acc, fn) => fn(acc, action),
    state
  );

export const initialState = (tab: string): State => ({
  selectedStopId: null,
  selectedModes: [],
  shouldFilterStopCards: false,
  selectedTab: tab
});

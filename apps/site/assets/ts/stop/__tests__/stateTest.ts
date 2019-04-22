import {
  reducer,
  clickMarkerAction,
  StopAction,
  clickModeAction,
  State,
  clickRoutePillAction
} from "../state";

describe("reducer", () => {
  it("handles clickMarkerAction by selecting a stop", () => {
    const initialState: State = {
      selectedStopId: null,
      selectedModes: [],
      shouldFilterStopCards: false,
      selectedTab: "info"
    };
    const expectedState: State = {
      ...initialState,
      selectedStopId: "1",
      shouldFilterStopCards: true,
      selectedTab: "info"
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickMarkerAction by deselecting a stop", () => {
    const initialState: State = {
      selectedStopId: "1",
      selectedModes: [],
      shouldFilterStopCards: true,
      selectedTab: "info"
    };
    const expectedState: State = {
      ...initialState,
      selectedStopId: null,
      shouldFilterStopCards: false,
      selectedTab: "info"
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickModeAction by adding a mode to filter by", () => {
    const initialState: State = {
      selectedStopId: null,
      selectedModes: ["subway"],
      shouldFilterStopCards: false,
      selectedTab: "alerts"
    };
    const expectedState: State = {
      ...initialState,
      selectedModes: ["subway", "bus"],
      shouldFilterStopCards: true,
      selectedTab: "info"
    };

    const newState = reducer(initialState, clickModeAction("bus"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickModeAction by removing a mode to filter by", () => {
    const initialState: State = {
      selectedStopId: null,
      selectedModes: ["subway", "bus"],
      shouldFilterStopCards: false,
      selectedTab: "info"
    };
    const expectedState: State = {
      ...initialState,
      selectedModes: ["subway"],
      shouldFilterStopCards: true,
      selectedTab: "info"
    };

    const newState = reducer(initialState, clickModeAction("bus"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickRoutePillAction by replacing mode to filter by", () => {
    const initialState: State = {
      selectedStopId: null,
      selectedModes: ["subway"],
      shouldFilterStopCards: true,
      selectedTab: "alerts"
    };
    const expectedState: State = {
      ...initialState,
      selectedModes: ["bus"],
      selectedTab: "info"
    };

    const newState = reducer(initialState, clickRoutePillAction("bus"));
    expect(newState).toEqual(expectedState);
  });

  it("would return default state if provided unknown type (but type is enforced by TS)", () => {
    const initialState: State = {
      selectedStopId: "1",
      selectedModes: [],
      shouldFilterStopCards: false,
      selectedTab: "info"
    };

    const action: StopAction = {
      // @ts-ignore
      type: "unknown",
      payload: { stopId: "null" }
    };
    const newState = reducer(initialState, action);

    expect(newState).toEqual(initialState);
  });
});

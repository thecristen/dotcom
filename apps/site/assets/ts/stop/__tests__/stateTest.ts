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
    const initialState = {
      selectedStopId: null,
      selectedModes: [],
      shouldFilterStopCards: false
    };
    const expectedState = {
      selectedStopId: "1",
      selectedModes: [],
      shouldFilterStopCards: true
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickMarkerAction by deselecting a stop", () => {
    const initialState = {
      selectedStopId: "1",
      selectedModes: [],
      shouldFilterStopCards: true
    };
    const expectedState = {
      selectedStopId: null,
      selectedModes: [],
      shouldFilterStopCards: false
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickModeAction by adding a mode to filter by", () => {
    const initialState: State = {
      selectedStopId: null,
      selectedModes: ["subway"],
      shouldFilterStopCards: false
    };
    const expectedState = {
      selectedStopId: null,
      selectedModes: ["subway", "bus"],
      shouldFilterStopCards: true
    };

    const newState = reducer(initialState, clickModeAction("bus"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickModeAction by removing a mode to filter by", () => {
    const initialState: State = {
      selectedStopId: null,
      selectedModes: ["subway", "bus"],
      shouldFilterStopCards: false
    };
    const expectedState = {
      selectedStopId: null,
      selectedModes: ["subway"],
      shouldFilterStopCards: true
    };

    const newState = reducer(initialState, clickModeAction("bus"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickRoutePillAction by replacing mode to filter by", () => {
    const initialState: State = {
      selectedStopId: null,
      selectedModes: ["subway"],
      shouldFilterStopCards: true
    };
    const expectedState: State = {
      ...initialState,
      selectedModes: ["bus"]
    };

    const newState = reducer(initialState, clickRoutePillAction("bus"));
    expect(newState).toEqual(expectedState);
  });

  it("would return default state if provided unknown type (but type is enforced by TS)", () => {
    const initialState = {
      selectedStopId: "1",
      selectedModes: [],
      shouldFilterStopCards: false
    };
    const expectedState = {
      selectedStopId: "1",
      selectedModes: [],
      shouldFilterStopCards: false
    };

    const action: StopAction = {
      // @ts-ignore
      type: "unknown",
      payload: { stopId: "null" }
    };
    const newState = reducer(initialState, action);

    expect(newState).toEqual(expectedState);
  });
});

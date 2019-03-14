import { reducer, clickMarkerAction, Action } from "../state";

describe("reducer", () => {
  it("handles clickMarkerAction by selecting a stop", () => {
    const initialState = {
      selectedStopId: null
    };
    const expectedState = {
      selectedStopId: "1"
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickMarkerAction by deselecting a stop", () => {
    const initialState = {
      selectedStopId: "1"
    };
    const expectedState = {
      selectedStopId: null
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("would return default state if provided unknown type (but type is enforced by TS)", () => {
    const initialState = {
      selectedStopId: "1"
    };
    const expectedState = {
      selectedStopId: "1"
    };

    const action: Action = {
      // @ts-ignore
      type: "unknown",
      payload: { stopId: "null" }
    };
    const newState = reducer(initialState, action);

    expect(newState).toEqual(expectedState);
  });
});

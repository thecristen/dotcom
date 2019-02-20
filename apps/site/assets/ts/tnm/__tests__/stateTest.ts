import {
  reducer,
  clickMarkerAction,
  clickCurrentLocationAction,
  clickStopCardAction,
  clickStopPillAction
} from "../state";

describe("reducer", () => {
  it("handles clickMarkerAction by selecting a stop", () => {
    const initialState = {
      selectedStopId: null,
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: true
    };
    const expectedState = {
      selectedStopId: "1",
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: false
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickMarkerAction by deselecting a stop", () => {
    const initialState = {
      selectedStopId: "1",
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: true
    };
    const expectedState = {
      selectedStopId: null,
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: false
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickCurrentLocationAction", () => {
    const initialState = {
      selectedStopId: null,
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: true
    };
    const expectedState = {
      selectedStopId: "1",
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: false
    };

    const newState = reducer(initialState, clickCurrentLocationAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickStopCardAction", () => {
    const initialState = {
      selectedStopId: null,
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: false
    };
    const expectedState = {
      selectedStopId: "1",
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: true
    };

    const newState = reducer(initialState, clickStopCardAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickStopPillAction", () => {
    const initialState = {
      selectedStopId: "1",
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: true
    };
    const expectedState = {
      selectedStopId: null,
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: false
    };

    const newState = reducer(initialState, clickStopPillAction());

    expect(newState).toEqual(expectedState);
  });
});

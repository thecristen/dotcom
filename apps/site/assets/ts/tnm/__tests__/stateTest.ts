import {
  reducer,
  clickMarkerAction,
  clickCurrentLocationAction,
  clickStopCardAction,
  clickStopPillAction,
  clickViewChangeAction,
  clickModeAction,
  StopAction
} from "../state";

describe("reducer", () => {
  it("handles clickMarkerAction by selecting a stop", () => {
    const initialState = {
      selectedStopId: null,
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: true,
      routesView: true,
      selectedModes: []
    };
    const expectedState = {
      selectedStopId: "1",
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: false,
      routesView: true,
      selectedModes: []
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickMarkerAction by deselecting a stop", () => {
    const initialState = {
      selectedStopId: "1",
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: true,
      routesView: true,
      selectedModes: []
    };
    const expectedState = {
      selectedStopId: null,
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: false,
      routesView: true,
      selectedModes: []
    };

    const newState = reducer(initialState, clickMarkerAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickCurrentLocationAction", () => {
    const initialState = {
      selectedStopId: null,
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: true,
      routesView: true,
      selectedModes: []
    };
    const expectedState = {
      selectedStopId: "1",
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: false,
      routesView: true,
      selectedModes: []
    };

    const newState = reducer(initialState, clickCurrentLocationAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickStopCardAction", () => {
    const initialState = {
      selectedStopId: null,
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: false,
      routesView: true,
      selectedModes: []
    };
    const expectedState = {
      selectedStopId: "1",
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: true,
      routesView: true,
      selectedModes: []
    };

    const newState = reducer(initialState, clickStopCardAction("1"));

    expect(newState).toEqual(expectedState);
  });

  it("handles clickStopPillAction", () => {
    const initialState = {
      selectedStopId: "1",
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: true,
      routesView: true,
      selectedModes: []
    };
    const expectedState = {
      selectedStopId: null,
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: false,
      routesView: true,
      selectedModes: []
    };

    const newState = reducer(initialState, clickStopPillAction());

    expect(newState).toEqual(expectedState);
  });

  it("handles clickViewChangeAction", () => {
    const initialState = {
      selectedStopId: "1",
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: true,
      routesView: true,
      selectedModes: []
    };
    const expectedState = {
      selectedStopId: null,
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: false,
      routesView: false,
      selectedModes: []
    };

    const newState = reducer(initialState, clickViewChangeAction());

    expect(newState).toEqual(expectedState);
  });

  it("would return default state if provided unknown type (but type is enforced by TS)", () => {
    const initialState = {
      selectedStopId: "1",
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: false,
      routesView: true,
      selectedModes: []
    };
    const expectedState = {
      selectedStopId: "1",
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: false,
      routesView: true,
      selectedModes: []
    };

    const action: StopAction = {
      // @ts-ignore
      type: "unknown",
      payload: { stopId: "null" }
    };
    const newState = reducer(initialState, action);

    expect(newState).toEqual(expectedState);
  });

  it("handles clickModeAction", () => {
    const initialState = {
      selectedStopId: null,
      shouldFilterStopCards: false,
      shouldCenterMapOnSelectedStop: true,
      routesView: true,
      selectedModes: []
    };

    const expectedState = {
      selectedStopId: null,
      shouldFilterStopCards: true,
      shouldCenterMapOnSelectedStop: true,
      routesView: true,
      selectedModes: ["subway", "bus"]
    };

    const newState = reducer(initialState, clickModeAction(["subway", "bus"]));

    expect(newState).toEqual(expectedState);
  });
});

import React from "react";
import { shallow } from "enzyme";
import Marker from "../../components/googleMaps/Marker";
import { createReactRoot } from "../helpers/testUtils";
import { MarkerData } from "../../components/__tnm";

const createData = (id: string): MarkerData => ({
  id,
  latitude: 0,
  longitude: 0,
  icon: null,
  "visible?": true,
  size: "tiny",
  tooltip: "THIS IS A TOOLTIP",
  z_index: 0, // eslint-disable-line typescript/camelcase
  label: null
});

describe("Marker", () => {
  const map = new window.google.maps.Map();
  const id = "id";
  it("it renders", () => {
    const data = createData(id);
    createReactRoot();
    const wrapper = shallow(
      <Marker map={map} data={data} isSelected={false} dispatch={() => {}} />
    );
    expect(wrapper.find(`.${id}`)).toHaveLength(1);
  });

  it("handles marker clicks", () => {
    const data = createData(id);
    const spy = jest.fn();
    const marker = new Marker({
      map,
      data,
      isSelected: false,
      dispatch: spy
    });
    marker.handleMarkerClick();
    expect(spy).toHaveBeenCalledWith({
      payload: { stopId: id },
      type: "CLICK_MARKER"
    });
  });

  it("handles current-location marker clicks", () => {
    const spy = jest.fn();
    const data = createData("current-location");
    const marker = new Marker({
      map,
      data,
      isSelected: false,
      dispatch: spy
    });
    marker.handleMarkerClick();
    expect(spy).toHaveBeenCalledWith({
      payload: { stopId: "current-location" },
      type: "CLICK_CURRENT_LOCATION_MARKER"
    });
  });

  it("handles info window clicks", () => {
    const data = createData(id);
    const spy = jest.fn();
    const marker = new Marker({
      map,
      data,
      isSelected: false,
      dispatch: spy
    });
    marker.handleInfoWindowClick();
    expect(spy).toHaveBeenCalledWith({
      payload: { stopId: null },
      type: "CLICK_MARKER"
    });
  });
});

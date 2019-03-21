import React from "react";
import renderer from "react-test-renderer";
import { mount } from "enzyme";
import BikeStorageInfo from "../components/BikeStorageInfo";
import { BikeStorage, Stop } from "../../__v3api";
import {
  createReactRoot,
  enzymeToJsonWithoutProps
} from "../../app/helpers/testUtils";
/* eslint-disable typescript/camelcase */

const bikeStorages: BikeStorage[] = [
  "bike_storage_cage",
  "bike_storage_rack",
  "bike_storage_rack_covered"
];

const stop: Stop = {
  "station?": true,
  parking_lots: [],
  note: null,
  name: "South Station",
  bike_storage: bikeStorages,
  fare_facilities: [],
  longitude: -71.055242,
  latitude: 42.352271,
  "is_child?": false,
  id: "place-sstat",
  "has_fare_machine?": true,
  "has_charlie_card_vendor?": false,
  closed_stop_info: null,
  address: "700 Atlantic Ave, Boston, MA 02110",
  accessibility: [
    "accessible",
    "escalator_both",
    "elevator",
    "fully_elevated_platform"
  ]
};

const id = "#header-bikes";

describe("ParkingInfo", () => {
  it("it renders", () => {
    createReactRoot();
    const tree = renderer.create(<BikeStorageInfo stop={stop} />).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it("via enzyme-to-json it displays parking info when opened and inner html", () => {
    createReactRoot();
    const wrapper = mount(<BikeStorageInfo stop={stop} />);
    wrapper.find(id).simulate("click");
    expect(enzymeToJsonWithoutProps(wrapper)).toMatchSnapshot();
  });

  it("handles cases where an unknown bike storage type is provided", () => {
    // @ts-ignore for runtime testing from API
    const unknownBikeStorages: BikeStorage[] = ["some_storage"];
    const stopWithNoLots = { ...stop, bike_storage: unknownBikeStorages };
    createReactRoot();
    const wrapper = mount(<BikeStorageInfo stop={stopWithNoLots} />);
    wrapper.find(id).simulate("click");
    expect(wrapper.text()).toContain("Regular bike racks");
  });

  it("handles cases where no parking information is listed for a station", () => {
    const stopWithNoLots = { ...stop, bike_storage: [] };
    createReactRoot();
    const wrapper = mount(<BikeStorageInfo stop={stopWithNoLots} />);
    wrapper.find(id).simulate("click");
    expect(wrapper.text()).toContain(
      "There is no bike parking information available for this station."
    );
  });

  it("handles cases where no parking information is listed for a stop", () => {
    const stopWithNoLots = { ...stop, "station?": false, bike_storage: [] };
    createReactRoot();
    const wrapper = mount(<BikeStorageInfo stop={stopWithNoLots} />);
    wrapper.find(id).simulate("click");
    expect(wrapper.text()).toContain("for this stop");
  });
});

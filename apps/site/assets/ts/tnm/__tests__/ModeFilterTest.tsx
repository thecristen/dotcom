import React from "react";
import renderer from "react-test-renderer";
import { mount } from "enzyme";
import { ModeFilter } from "../components/ModeFilter";
import { createReactRoot } from "../../app/helpers/testUtils";

describe("render", () => {
  it("renders", () => {
    createReactRoot();
    const tree = renderer
      .create(<ModeFilter dispatch={() => {}} selectedModes={[]} />)
      .toJSON();
    expect(tree).toMatchSnapshot();
  });

  it("calls clickModeAction when filter button is clicked", () => {
    createReactRoot();

    const mockDispatch = jest.fn();

    const wrapper = mount(
      <ModeFilter dispatch={mockDispatch} selectedModes={[]} />
    );

    wrapper
      .find(".m-tnm-sidebar__filter-btn")
      .first()
      .simulate("click");

    expect(mockDispatch).toHaveBeenCalledWith({
      type: "CLICK_MODE_FILTER",
      payload: { modes: ["subway"] }
    });
  });
});

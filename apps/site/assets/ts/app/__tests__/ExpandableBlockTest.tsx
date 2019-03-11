import React from "react";
import { mount } from "enzyme";
import renderer from "react-test-renderer";
import ExpandableBlock from "../ExpandableBlock";
// @ts-ignore
import accessibleIcon from "../../../static/images/icon-accessible-default.svg";

const body = '<div id="react-root"></div>';

test("render expandable block expanded by default", () => {
  document.body.innerHTML = body;

  const expandableComponent = (
    <ExpandableBlock
      initiallyExpanded
      id="accessibility"
      header={{
        text: "Accessibility",
        iconSvgText: accessibleIcon
      }}
    >
      <div>
        <p>South Station is accessible. It has the following features:</p>
        <p>This is a test</p>
      </div>
    </ExpandableBlock>
  );

  const tree = renderer.create(expandableComponent).toJSON();
  expect(tree).toMatchSnapshot();
});

test("handle click to expand and enter to collapse", () => {
  document.body.innerHTML = body;

  const wrapper = mount(
    <ExpandableBlock
      initiallyExpanded={false}
      id="accessibility"
      header={{
        text: "Accessibility",
        iconSvgText: accessibleIcon
      }}
    >
      <div>
        <p>South Station is accessible. It has the following features:</p>
        <p>This is a test</p>
      </div>
    </ExpandableBlock>
  );

  expect(
    wrapper.find(".c-expandable-block__header").prop("aria-expanded")
  ).toEqual(false);

  wrapper.find(".c-expandable-block__header").simulate("click");

  expect(
    wrapper.find(".c-expandable-block__header").prop("aria-expanded")
  ).toEqual(true);

  wrapper
    .find(".c-expandable-block__header")
    .simulate("keypress", { key: "Enter" });

  expect(
    wrapper.find(".c-expandable-block__header").prop("aria-expanded")
  ).toEqual(false);
});

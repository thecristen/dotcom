import React, { ReactElement } from "react";
import ExpandableBlock from "../../app/ExpandableBlock";
// @ts-ignore
import accessibleIcon from "../../../static/images/icon-accessible-default.svg";

const Sidebar = (): ReactElement<HTMLElement> => (
  <>
    <p>Sidebar</p>
    <ExpandableBlock
      initiallyExpanded={false}
      id="accessibility"
      header={{
        text: "Accessibility",
        iconSvgText: accessibleIcon
      }}
    >
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html:
            "<p>South Station is accessible. It has the following features:</p><p>This is a test</p>"
        }}
      />
    </ExpandableBlock>
  </>
);

export default Sidebar;

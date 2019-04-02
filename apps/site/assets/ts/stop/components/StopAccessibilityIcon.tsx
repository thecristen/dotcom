import React, { ReactElement } from "react";
import { Stop } from "../../__v3api";
import { accessibleIcon } from "../../helpers/icon";

export default ({ accessibility }: Stop): ReactElement<HTMLElement> | false =>
  accessibility.includes("accessible") && (
    <a href="#accessibility" className="m-stop-page__access-icon">
      <span className="m-stop-page__icon">
        {accessibleIcon("c-svg__icon-accessible-default")}
      </span>
    </a>
  );

import React, { KeyboardEvent } from "react";

export const handleEnterKeyPress = (
  e: KeyboardEvent,
  onClick: Function
): void => {
  if (e.key === "Enter") {
    onClick();
  }
};

export const renderSvg = (className: string, svgText: string): JSX.Element => (
  <span
    className={className}
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: svgText }}
  />
);

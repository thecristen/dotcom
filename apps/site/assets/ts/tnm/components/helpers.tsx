import React from "react";

const renderSvg = (className: string, svgText: string): JSX.Element => (
  <span
    className={className}
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: svgText }}
  />
);

// this is to address a warning about a module that exports only one function
// later if we add more helpers we can export them individually
export default renderSvg;

import React, { ReactElement, KeyboardEvent } from "react";
import { Stop } from "./__tnm";
import { clickStopPillAction } from "../state";

interface Props {
  selectedStop: Stop | undefined;
  dispatch: Function;
}

const handleKeyPress = (e: KeyboardEvent, onClick: Function): void => {
  if (e.key === "Enter") {
    onClick();
  }
};

const RouteSidebarHeader = (props: Props): ReactElement<HTMLElement> => {
  const { dispatch, selectedStop } = props;
  const onClick = (): void => dispatch(clickStopPillAction());
  return (
    <div className="m-tnm-sidebar__header">
      <h2>Nearby Routes</h2>
      {selectedStop && (
        <span
          role="button"
          tabIndex={0}
          className="m-tnm-sidebar__pill"
          onClick={onClick}
          onKeyPress={e => handleKeyPress(e, onClick)}
        >
          {selectedStop.name}
          <span className="m-tnm-sidebar__pill-close fa fa-times-circle" />
        </span>
      )}
    </div>
  );
};

export default RouteSidebarHeader;

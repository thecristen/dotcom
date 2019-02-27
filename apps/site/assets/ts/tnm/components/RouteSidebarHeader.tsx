import React, { ReactElement } from "react";
import { Stop } from "./__tnm";
import SidebarTitle from "./SidebarTitle";
import { clickStopPillAction, Dispatch } from "../state";
import { handleEnterKeyPress } from "./helpers";

interface Props {
  selectedStop: Stop | undefined;
  dispatch: Dispatch;
}

const RouteSidebarHeader = (props: Props): ReactElement<HTMLElement> => {
  const { dispatch, selectedStop } = props;
  const onClickPill = (): void => dispatch(clickStopPillAction());
  return (
    <div className="m-tnm-sidebar__header">
      <SidebarTitle dispatch={dispatch} viewType="Routes" />
      {selectedStop && (
        <span
          role="button"
          tabIndex={0}
          className="m-tnm-sidebar__pill"
          onClick={onClickPill}
          onKeyPress={e => handleEnterKeyPress(e, onClickPill)}
          aria-label={`Remove filtering by ${selectedStop.name}`}
        >
          {selectedStop.name}
          <span className="m-tnm-sidebar__pill-close fa fa-times-circle" />
        </span>
      )}
    </div>
  );
};

export default RouteSidebarHeader;

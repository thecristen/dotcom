import React, { ReactElement } from "react";
import { TNMStop } from "./__tnm";
import SidebarTitle from "./SidebarTitle";
import { clickStopPillAction, Dispatch } from "../state";
import { handleReactEnterKeyPress } from "../../helpers/keyboard-events";

interface Props {
  selectedStop: TNMStop | undefined;
  dispatch: Dispatch;
  showPill: boolean;
}

const RouteSidebarHeader = (props: Props): ReactElement<HTMLElement> => {
  const { dispatch, selectedStop, showPill } = props;
  const onClickPill = (): void => dispatch(clickStopPillAction());
  return (
    <div className="m-tnm-sidebar__header">
      <SidebarTitle dispatch={dispatch} viewType="Routes" />
      {showPill && selectedStop && (
        <span
          role="button"
          tabIndex={0}
          className="m-tnm-sidebar__pill"
          onClick={onClickPill}
          onKeyPress={e => handleReactEnterKeyPress(e, onClickPill)}
          aria-label={`Remove filtering by ${selectedStop.name}`}
        >
          <span className="m-tnm-sidebar__pill-name">{selectedStop.name}</span>
          <span className="m-tnm-sidebar__pill-close fa fa-times-circle" />
        </span>
      )}
    </div>
  );
};

export default RouteSidebarHeader;

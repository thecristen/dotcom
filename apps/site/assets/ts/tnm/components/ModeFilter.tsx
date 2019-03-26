import React, { ReactElement } from "react";
import { clickModeAction, Dispatch } from "../state";
import { TNMMode } from "./__tnm";
import ModeIcon from "./ModeIcon";

interface Props {
  dispatch: Dispatch;
  selectedModes: TNMMode[];
}

interface ModeButtonProps {
  mode: TNMMode;
  icon: string;
  name: string;
}

interface TNMModeByV3ModeType {
  [s: number]: TNMMode;
}

export const tnmModeByV3ModeType: TNMModeByV3ModeType = {
  0: "subway",
  1: "subway",
  2: "rail",
  3: "bus"
};

export const ModeFilter = ({
  dispatch,
  selectedModes
}: Props): ReactElement<HTMLElement> => {
  const handleClickMode = (mode: TNMMode): void => {
    const updatedModes = selectedModes.includes(mode)
      ? selectedModes.filter(existingMode => !(existingMode === mode))
      : [...selectedModes, mode];

    dispatch(clickModeAction(updatedModes));
  };

  const ModeButton = ({
    mode,
    icon,
    name
  }: ModeButtonProps): ReactElement<HTMLElement> => (
    <button
      className={`btn btn-secondary btn-sm m-tnm-sidebar__filter-btn ${
        selectedModes.includes(mode) ? "active" : "inactive"
      }`}
      onClick={() => handleClickMode(mode)}
      type="button"
      aria-label={
        selectedModes.includes(mode)
          ? `remove filter by ${mode}`
          : `add filter by ${mode}`
      }
    >
      <ModeIcon type={icon} />
      {name}
    </button>
  );

  return (
    <div className="m-tnm-sidebar__filter-bar">
      <div className="m-tnm-sidebar__filter-bar-inner">
        <span className="m-tnm-sidebar__filter-header">Filter</span>
        <ModeButton mode="subway" icon="subway" name="Subway" />
        <ModeButton mode="bus" icon="bus" name="Bus" />
        <ModeButton mode="rail" icon="commuter_rail" name="Rail" />
      </div>
    </div>
  );
};

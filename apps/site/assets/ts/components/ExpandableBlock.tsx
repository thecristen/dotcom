import React, { ReactElement, useState } from "react";
import { handleReactEnterKeyPress } from "../helpers/keyboard-events";
import renderSvg from "../helpers/render-svg";
import { caret } from "../helpers/icon";

export interface ExpandableBlockHeader {
  text: string;
  iconSvgText: string | null;
}

interface Props {
  initiallyExpanded: boolean;
  header: ExpandableBlockHeader;
  children: ReactElement<HTMLElement>;
  id: string;
}

interface State {
  expanded: boolean;
  focused: boolean;
}

export default ({
  initiallyExpanded,
  header: { text, iconSvgText },
  children,
  id
}: Props): ReactElement<HTMLElement> => {
  const [state, toggleExpanded] = useState({
    expanded: initiallyExpanded,
    focused: false
  });
  const { expanded, focused }: State = state;
  const headerId = `header-${id}`;
  const panelId = `panel-${id}`;

  const onClick = (): void =>
    toggleExpanded({ expanded: !expanded, focused: true });

  return (
    <>
      <h3
        className="c-expandable-block__header"
        tabIndex={0}
        id={headerId}
        aria-expanded={expanded}
        aria-controls={panelId}
        // eslint-disable-next-line jsx-a11y/no-noninteractive-element-to-interactive-role
        role="button"
        onClick={onClick}
        onKeyPress={e => handleReactEnterKeyPress(e, onClick)}
      >
        {iconSvgText
          ? renderSvg("c-expandable-block__header-icon", iconSvgText)
          : null}
        {text}
        {caret("c-expandable-block__header-caret", expanded)}
      </h3>
      {expanded ? (
        <div
          className="c-expandable-block__panel"
          // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
          tabIndex={0}
          role="region"
          id={panelId}
          aria-labelledby={headerId}
          ref={panel => panel && focused && panel.focus()}
        >
          {children}
        </div>
      ) : null}
      {/* No javascript support */}
      <noscript>
        <style>{`#${headerId} { display: none; }`}</style>
        <h3 className="c-expandable-block__header">
          {iconSvgText
            ? renderSvg("c-expandable-block__header-icon", iconSvgText)
            : null}
          {text}
          {caret("c-expandable-block__header-caret", true)}
        </h3>
        <div className="c-expandable-block__panel" role="region">
          {children}
        </div>
      </noscript>
    </>
  );
};

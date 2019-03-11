import React, { ReactElement, useState } from "react";
import { handleReactEnterKeyPress } from "../helpers/keyboard-events";
import renderSvg from "../helpers/render-svg";

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

const caret = (expanded: boolean): ReactElement<HTMLElement> => {
  const unicodeCharacter = expanded ? "&#xF107;" : "&#xF106;";
  return (
    <span
      className="c-expandable-block__header-caret"
      // eslint-disable-next-line react/no-danger
      dangerouslySetInnerHTML={{ __html: unicodeCharacter }}
    />
  );
};

export default ({
  initiallyExpanded,
  header: { text, iconSvgText },
  children,
  id
}: Props): ReactElement<HTMLElement> => {
  const [expanded, toggleExpanded] = useState(initiallyExpanded);
  const headerId = `header-${id}`;
  const panelId = `panel-${id}`;

  const onClick = (): void => toggleExpanded(!expanded);

  return (
    <>
      <div
        className="c-expandable-block__header"
        tabIndex={0}
        id={headerId}
        aria-expanded={expanded}
        aria-controls={panelId}
        role="button"
        onClick={onClick}
        onKeyPress={e => handleReactEnterKeyPress(e, onClick)}
      >
        {iconSvgText
          ? renderSvg("c-expandable-block__header-icon", iconSvgText)
          : null}
        {text}
        {caret(expanded)}
      </div>
      {expanded ? (
        <div
          className="c-expandable-block__panel"
          // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
          tabIndex={0}
          role="region"
          id={panelId}
          aria-labelledby={headerId}
          ref={panel => panel && panel.focus()}
        >
          {children}
        </div>
      ) : null}
    </>
  );
};

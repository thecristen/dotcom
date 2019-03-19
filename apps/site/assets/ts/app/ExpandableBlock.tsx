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
  const unicodeCharacter = expanded ? "&#xF106;" : "&#xF107;";
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
        {caret(expanded)}
      </h3>
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
      {/* No javascript support */}
      <noscript>
        <style>{`#${headerId} { display: none; }`}</style>
        <h3 className="c-expandable-block__header">
          {iconSvgText
            ? renderSvg("c-expandable-block__header-icon", iconSvgText)
            : null}
          {text}
          {caret(true)}
        </h3>
        <div className="c-expandable-block__panel" role="region">
          {children}
        </div>
      </noscript>
    </>
  );
};

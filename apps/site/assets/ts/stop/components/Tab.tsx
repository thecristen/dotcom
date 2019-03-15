import React, { ReactElement } from "react";
import { Tab, TabBadge } from "./__stop";

interface Props {
  tab: Tab;
}

const selectedClass = ({ id }: Tab): string =>
  id === "details" ? "header-tab--selected" : "";

const BadgeComponent = (badge: TabBadge): ReactElement<HTMLElement> => (
  <div className={badge.class} aria-label={badge.aria_label}>
    {badge.content}
  </div>
);

const TabComponent = ({ tab }: Props): ReactElement<HTMLElement> => (
  <a
    href={tab.href}
    className={`
      header-tab
      header-tab--dark
      ${selectedClass(tab)}
      ${tab.class}
      ${tab.id}
    `}
  >
    {tab.name}
    {tab.badge && BadgeComponent(tab.badge)}
  </a>
);

export default TabComponent;

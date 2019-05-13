import React, { ReactElement } from "react";
import ExpandableBlock from "../../components/ExpandableBlock";
import { Fare } from "./__schedule";

const fareItem = (fare: Fare): ReactElement<HTMLElement> => (
  <p key={fare.title} className="m-schedule-page__fare">
    <span>{fare.title}</span>
    <span>{fare.price}</span>
  </p>
);

interface Props {
  fares: Fare[];
  fareLink: string;
}

const Fares = ({ fares, fareLink }: Props): ReactElement<HTMLElement> | null =>
  fares.length > 0 ? (
    <ExpandableBlock
      header={{ text: "Fares", iconSvgText: null }}
      initiallyExpanded={false}
      id="fares"
    >
      <>
        {fares.map(f => fareItem(f))}
        <p className="m-schedule-page__link">
          <a className="c-call-to-action" href={fareLink}>
            More about fares
          </a>
        </p>
      </>
    </ExpandableBlock>
  ) : null;

export default Fares;

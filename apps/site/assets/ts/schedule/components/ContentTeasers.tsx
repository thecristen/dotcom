import React, { ReactElement } from "react";

interface Props {
  teasers: string | null;
}

const ContentTeasers = ({ teasers }: Props): ReactElement<HTMLElement> | null =>
  teasers ? <div dangerouslySetInnerHTML={{ __html: teasers }} /> : null;

export default ContentTeasers;

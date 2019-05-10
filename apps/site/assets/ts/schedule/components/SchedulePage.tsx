import React, { ReactElement } from "react";
import { SchedulePageData } from "./__schedule";
import PDFSchedules from "./PDFSchedules";
import ContentTeasers from "./ContentTeasers";
import HoursOfOperation from "./HoursOfOperation";

interface Props {
  schedulePageData: SchedulePageData;
}

const SchedulePage = ({
  schedulePageData: { pdfs, teasers, hours }
}: Props): ReactElement<HTMLElement> => (
  <>
    <ContentTeasers teasers={teasers} />
    <PDFSchedules pdfs={pdfs} />
    <HoursOfOperation hours={hours} />
  </>
);
export default SchedulePage;

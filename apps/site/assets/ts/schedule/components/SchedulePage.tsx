import React, { ReactElement } from "react";
import { SchedulePageData } from "./__schedule";
import PDFSchedules from "./PDFSchedules";
import ContentTeasers from "./ContentTeasers";
import HoursOfOperation from "./HoursOfOperation";
import Fares from "./Fares";

interface Props {
  schedulePageData: SchedulePageData;
}

const SchedulePage = ({
  schedulePageData: { pdfs, teasers, hours, fares, fare_link: fareLink }
}: Props): ReactElement<HTMLElement> => (
  <>
    <ContentTeasers teasers={teasers} />
    <PDFSchedules pdfs={pdfs} />
    <Fares fares={fares} fareLink={fareLink} />
    <HoursOfOperation hours={hours} />
  </>
);
export default SchedulePage;

import React, { ReactElement } from "react";
import { SchedulePageData } from "./__schedule";
import PDFSchedules from "./PDFSchedules";

interface Props {
  schedulePageData: SchedulePageData;
}

const SchedulePage = ({
  schedulePageData: { pdfs }
}: Props): ReactElement<HTMLElement> => <PDFSchedules pdfs={pdfs} />;
export default SchedulePage;

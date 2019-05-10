// import {  } from "../../__v3api";

export interface SchedulePageData {
  pdfs: SchedulePDF[];
  teasers: string | null;
  hours: string;
}

export interface SchedulePDF {
  title: string;
  url: string;
}

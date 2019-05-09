// import {  } from "../../__v3api";

export interface SchedulePageData {
  pdfs: SchedulePDF[];
  teasers: string | null;
}

export interface SchedulePDF {
  title: string;
  url: string;
}

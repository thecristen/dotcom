// import {  } from "../../__v3api";

export interface SchedulePageData {
  pdfs: SchedulePDF[];
  teasers: string | null;
  hours: string;
  fares: Fare[];
  fare_link: string;
}

export interface SchedulePDF {
  title: string;
  url: string;
}

export interface Fare {
  title: string;
  price: string;
}

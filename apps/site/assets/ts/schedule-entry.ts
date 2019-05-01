import * as Sentry from "@sentry/browser";
import googleMapsLoaded from "../js/google-maps-loaded";
import schedule from "./schedule/schedule-loader";

/* eslint-disable no-undef */
// @ts-ignore webpack constants
if (process.env.NODE_ENV === "production" && SENTRY_DSN) {
  Sentry.init({
    // @ts-ignore webpack constants
    dsn: SENTRY_DSN
  });
}
/* eslint-enable no-undef */

googleMapsLoaded();
schedule();

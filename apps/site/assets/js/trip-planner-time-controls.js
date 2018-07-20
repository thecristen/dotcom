import DatePickerInput from "./datepicker-input";

export class TripPlannerTimeControls {
  constructor() {
    this.hideControls();
    const { dateEl, month, day, year } = TripPlannerTimeControls.SELECTORS;
    this.DatePicker = new DatePickerInput({
      selectors: { dateEl, month, day, year },
      onUpdateCallback: this.updateAccordionTitleCallback.bind(this)
    });
    this.timeInput();
    this.accordionSetup();
  }

  accordionSetup() {
    document
      .getElementById(TripPlannerTimeControls.SELECTORS.depart)
      .addEventListener("click", () => {
        this.showControls();
        this.updateAccordionTitle("Depart at");
      });
    document
      .getElementById(TripPlannerTimeControls.SELECTORS.arrive)
      .addEventListener("click", () => {
        this.showControls();
        this.updateAccordionTitle("Arrive by");
      });
    document
      .getElementById(TripPlannerTimeControls.SELECTORS.leaveNow)
      .addEventListener("click", () => {
        this.hideControls();
        this.updateAccordionTitle("Leave now", false);
      });
    $(`#${TripPlannerTimeControls.SELECTORS.title}`).data(
      "prefix",
      "Leave now"
    );
    this.updateAccordionTitle("Leave now", false);
  }

  timeInput() {
    document
      .getElementById(TripPlannerTimeControls.SELECTORS.hour)
      .addEventListener("change", this.updateTime.bind(this));
    document
      .getElementById(TripPlannerTimeControls.SELECTORS.minute)
      .addEventListener("change", this.updateTime.bind(this));
    document
      .getElementById(TripPlannerTimeControls.SELECTORS.amPm)
      .addEventListener("change", this.updateTime.bind(this));
    this.updateTime();
  }

  updateTime() {
    const time = new Date();
    const hour12 =
      parseInt(
        document.getElementById(TripPlannerTimeControls.SELECTORS.hour).value,
        10
      ) % 12;
    const amPm = document.getElementById(TripPlannerTimeControls.SELECTORS.amPm)
      .value;
    const hour = amPm === "PM" ? hour12 + 12 : hour12;
    const timeLabel = document.getElementById(
      TripPlannerTimeControls.SELECTORS.timeEl.label
    );
    const ariaMessage = timeLabel.getAttribute("aria-label").split(", ")[1];
    time.setHours(hour);
    time.setMinutes(
      document.getElementById(TripPlannerTimeControls.SELECTORS.minute).value
    );
    const friendlyTime = TripPlannerTimeControls.getFriendlyTime(time);

    timeLabel.setAttribute("data-time", friendlyTime);
    timeLabel.setAttribute("aria-label", `${friendlyTime}, ${ariaMessage}`);
    this.updateAccordionTitle(
      document
        .getElementById(TripPlannerTimeControls.SELECTORS.title)
        .getAttribute("data-prefix")
    );
  }

  updateAccordionTitle(text, showDate = true) {
    let title = text;
    if (showDate) {
      const timeEl = document.getElementById(
        TripPlannerTimeControls.SELECTORS.timeEl.label
      );
      const time = timeEl.getAttribute("data-time");
      const dateEl = document.getElementById(
        TripPlannerTimeControls.SELECTORS.dateEl.label
      );
      const date = dateEl.getAttribute("data-date");
      title = `${text} ${time}, ${date}`;
    }
    const accordionTitle = document.getElementById(
      TripPlannerTimeControls.SELECTORS.title
    );
    accordionTitle.innerHTML = title;
    accordionTitle.setAttribute("data-prefix", text);
  }

  updateAccordionTitleCallback() {
    const text = document
      .getElementById(TripPlannerTimeControls.SELECTORS.title)
      .getAttribute("data-prefix");
    this.updateAccordionTitle(text);
  }

  static getFriendlyTime(datetime) {
    let amPm = "AM";
    let hour = datetime.getHours();
    let minute = datetime.getMinutes();

    if (hour > 11) {
      amPm = "PM";
    }
    if (hour > 12) {
      hour -= 12;
    }
    if (hour === 0) {
      hour = 12;
    }

    if (minute < 10) {
      minute = `0${minute}`;
    }

    return `${hour}:${minute} ${amPm}`;
  }

  hideControls() {
    const $ = window.jQuery;
    $(`#${TripPlannerTimeControls.SELECTORS.controls}`).hide();
  }

  showControls() {
    const $ = window.jQuery;
    $(`#${TripPlannerTimeControls.SELECTORS.controls}`).show();
  }
}

TripPlannerTimeControls.SELECTORS = {
  depart: "depart",
  leaveNow: "leave-now",
  arrive: "arrive",
  controls: "trip-plan-datepicker",
  year: "plan_date_time_year",
  month: "plan_date_time_month",
  day: "plan_date_time_day",
  hour: "plan_date_time_hour",
  minute: "plan_date_time_minute",
  amPm: "plan_date_time_am_pm",
  dateEl: {
    container: "plan-date",
    input: "plan-date-input",
    select: "plan-date-select",
    label: "plan-date-label"
  },
  timeEl: {
    container: "plan-time",
    select: "plan-time-select",
    label: "plan-time-label"
  },
  title: "trip-plan-accordion-title"
};

export function init() {
  const $ = window.jQuery;
  $(document).on("turbolinks:load", () => {
    const tripPlanner = new TripPlannerTimeControls();
  });
}

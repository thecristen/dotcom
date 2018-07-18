import { triggerResize } from "./google-map";

const DATE_TIME_IDS = {
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
  }
};

export class TripPlan {
  constructor() {
    const $ = window.jQuery;
    $(document).on(
      "focus",
      "#to.trip-plan-current-location",
      TripPlan.highlightCurrentLocation($)
    );
    $(document).on(
      "focus",
      "#from.trip-plan-current-location",
      TripPlan.highlightCurrentLocation($)
    );
    $(document).on(
      "input",
      "#to.trip-plan-current-location",
      TripPlan.clearCurrentLocation($)
    );
    $(document).on(
      "input",
      "#from.trip-plan-current-location",
      TripPlan.clearCurrentLocation($)
    );
    $(document).on("click", "#depart", TripPlan.showDatePicker($));
    $(document).on("click", "#arrive", TripPlan.showDatePicker($));
    $(document).on("click", "#leave-now", TripPlan.hideDatePicker($));
    $(document).on("click", "#trip-plan-reverse-control", TripPlan.reverseTrip());
    $(document).on(
      "click",
      "#depart",
      TripPlan.updateAccordionTitle("Depart at", true)
    );
    $(document).on(
      "click",
      "#arrive",
      TripPlan.updateAccordionTitle("Arrive by", true)
    );
    $(document).on(
      "click",
      "#leave-now",
      TripPlan.updateAccordionTitle("Leave now", false)
    );
    $("[data-planner-body]").on("hide.bs.collapse", TripPlan.toggleIcon);
    $("[data-planner-body]").on("show.bs.collapse", TripPlan.toggleIcon);
    $("[data-planner-body]").on("shown.bs.collapse", TripPlan.redrawMap);
    $(".itinerary-alert-toggle").on("click", TripPlan.toggleAlertDropdownText);
    if (navigator.userAgent.search("Firefox") > 0) {
      // We only want to load map images if they're actually being // used, to avoid spending money unnecessarily.
      // Normally, that's accomplished by using background-image: url(); however, Firefox hides background images by
      // default in printouts. This is a hack to load the static map image on Firefox only when javascript is enabled
      // and the user has requested to print the page. The image is only visible under the @media print query, so
      // it does not need to be removed after printing.
      window.addEventListener("beforeprint", TripPlan.firefoxPrintStaticMap);
    } else if (navigator.userAgent.search("CasperJS") === 0) {
      // All other browsers load background images as expected when printing, so we set the background image url
      // and remove the unnecessary image tag. Background images are only loaded when their element becomes visible,
      // so the image will not be loaded unless the user activates the Print media query.
      //
      // Note that we also skip this when running in backstop as this was breaking backstop rendering with CasperJS
      Array.from(document.getElementsByClassName("map-static")).map(div => {
        div.setAttribute(
          "style",
          `background-image: url(${div.getAttribute("data-static-url")})`
        );
        return div.setAttribute("data-static-url", null);
      });
    }
  }

  static firefoxPrintStaticMap() {
    const expanded = Array.from(
      document.getElementsByClassName("trip-plan-itinerary-body")
    ).find(el => el.classList.contains("in"));
    if (expanded) {
      const container = document.getElementById(`${expanded.id}-map-static`);
      const img = document.createElement("img");
      img.src = container.getAttribute("data-static-url");
      img.classList.add("map-print");
      container.appendChild(img);
    }
  }

  dateInput() {
    const $dateInput = $(`#${DATE_TIME_IDS.dateEl.input}`);
    const dateLabel = document.getElementById(DATE_TIME_IDS.dateEl.label);
    const actualMonth = parseInt(
      document.getElementById(DATE_TIME_IDS.month).value,
      10
    );
    const minAllowedDate = $dateInput.data("min-date");
    const maxAllowedDate = $dateInput.data("max-date");
    const date = new Date(
      document.getElementById(DATE_TIME_IDS.year).value,
      actualMonth - 1,
      document.getElementById(DATE_TIME_IDS.day).value
    );

    dateLabel.dataset.date = TripPlan.getShortDate(date);

    $dateInput.datepicker({
      outputFormat: "EEEE, MMMM dd, yyyy",
      onUpdate: TripPlan.updateDate.bind(this, $),
      min: minAllowedDate,
      max: maxAllowedDate
    });

    // disable clicking on the month to change the grid type
    $(".datepicker-month").off();

    // remove fast-skip buttons
    $(".datepicker-month-fast-next").remove();
    $(".datepicker-month-fast-prev").remove();

    // replace default datepicker arrow icons
    $(".datepicker-calendar")
      .find(".glyphicon")
      .removeClass("glyphicon")
      .addClass("fa");
    $(".datepicker-calendar")
      .find(".glyphicon-triangle-right")
      .removeClass("glyphicon-triangle-right")
      .addClass("fa-caret-right");
    $(".datepicker-calendar")
      .find(".glyphicon-triangle-left")
      .removeClass("glyphicon-triangle-left")
      .addClass("fa-caret-left");

    $(document).on("click", `#${DATE_TIME_IDS.dateEl.input}`, ev => {
      ev.preventDefault();
      ev.stopPropagation();
      $(`#${DATE_TIME_IDS.dateEl.input}`).datepicker("show");
    });

    $dateInput.datepicker("setDate", date);
    $dateInput.datepicker("update");
  }

  static getShortDate(date) {
    const options = {
      year: "numeric",
      month: "numeric",
      day: "numeric"
    };
    return date.toLocaleDateString("en-US", options);
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

  static updateDate($, datepickerDate) {
    const date = new Date(datepickerDate);
    const month = date.getMonth() + 1;
    const dateLabel = document.getElementById(DATE_TIME_IDS.dateEl.label);
    const ariaMessage = dateLabel.getAttribute("aria-label").split(", ")[3];
    dateLabel.setAttribute("data-date", TripPlan.getShortDate(date));
    dateLabel.setAttribute("aria-label", `${datepickerDate}, ${ariaMessage}`);
    TripPlan.updateDateSelect(
      DATE_TIME_IDS.year,
      date.getFullYear().toString()
    );
    TripPlan.updateDateSelect(DATE_TIME_IDS.month, month.toString());
    TripPlan.updateDateSelect(DATE_TIME_IDS.day, date.getDate().toString());

    $(`#${DATE_TIME_IDS.dateEl.input}`).datepicker("hide");
    TripPlan.doUpdateAccordionTitle(
      document.getElementById("trip-plan-accordion-title").dataset.prefix,
      true
    );
  }

  static updateDateSelect(id, newValue) {
    const options = document.getElementById(id);
    const currentOpt = options.querySelector("option[selected='selected']");
    const newOpt = options.querySelector(`option[value='${newValue}']`);
    currentOpt.removeAttribute("selected");
    if (!newOpt) {
      options.append(
        $(
          `<option value="${newValue}" selected="selected">${newValue}</option>`
        )
      );
    } else {
      newOpt.setAttribute("selected", "selected");
    }
  }

  static timeInput($) {
    $(".datepicker-calendar").on("ab.datepicker.closed", TripPlan.updateTime);

    document
      .getElementById("plan_date_time_hour")
      .addEventListener("change", TripPlan.updateTime);
    document
      .getElementById("plan_date_time_minute")
      .addEventListener("change", TripPlan.updateTime);
    document
      .getElementById("plan_date_time_am_pm")
      .addEventListener("change", TripPlan.updateTime);
    TripPlan.updateTime();
  }

  static updateTime() {
    const time = new Date();
    const hour12 =
      parseInt(document.getElementById(DATE_TIME_IDS.hour).value, 10) % 12;
    const amPm = document.getElementById(DATE_TIME_IDS.amPm).value;
    const hour = amPm === "PM" ? hour12 + 12 : hour12;
    const timeLabel = document.getElementById(DATE_TIME_IDS.timeEl.label);
    const ariaMessage = timeLabel.getAttribute("aria-label").split(", ")[1];
    time.setHours(hour);
    time.setMinutes(document.getElementById(DATE_TIME_IDS.minute).value);
    const friendlyTime = TripPlan.getFriendlyTime(time);

    timeLabel.setAttribute("data-time", friendlyTime);
    timeLabel.setAttribute("aria-label", `${friendlyTime}, ${ariaMessage}`);
    TripPlan.doUpdateAccordionTitle(
      document
        .getElementById("trip-plan-accordion-title")
        .getAttribute("data-prefix"),
      true
    );
  }

  static targetFields($, e) {
    const fieldName = e.target.name;
    const baseName = /\[(\w+)\]/.exec(fieldName)[1];
    return {
      latitude: $(`[name='plan[${baseName}_latitude]']`),
      longitude: $(`[name='plan[${baseName}_longitude]']`)
    };
  }

  static highlightCurrentLocation($) {
    return e => {
      const $field = $(e.target);
      $field.select();
    };
  }

  static clearCurrentLocation($) {
    return e => {
      const $field = $(e.target);
      $field.removeClass("trip-plan-current-location");
      if ($field.val().length > 1) {
        $field.val("");
      }

      const targets = TripPlan.targetFields($, e);
      targets.latitude.val("");
      targets.longitude.val("");
    };
  }

  static toggleIcon(e) {
    const container = $(e.target).parent();
    const icon = $(container).find("[data-planner-header] i");
    icon.toggleClass("fa-plus-circle fa-minus-circle");
  }

  // There is a race condition that sometimes occurs on the initial render of the google map. It can't render properly
  // because it's container is being resized. This function is called after an itinerary is expanded to redraw the map
  // if necessary.
  static redrawMap(e) {
    const container = $(e.target).parent();
    const el = $(container).find(".trip-plan-itinerary-body .map-dynamic")[0];
    triggerResize(el);
  }

  static toggleAlertDropdownText(e) {
    const target = $(e.target);
    if (target.text() === "(view alert)") {
      target.text("(hide alert)");
    } else {
      target.text("(view alert)");
    }
  }

  static hideDatePicker($) {
    return () => {
      $("#trip-plan-datepicker").hide();
    };
  }

  static showDatePicker($) {
    return () => {
      $("#trip-plan-datepicker").show();
    };
  }

  static updateAccordionTitle(text, showDate) {
    return () => {
      TripPlan.doUpdateAccordionTitle(text, showDate);
    };
  }

  static doUpdateAccordionTitle(text, showDate) {
    let title = text;
    if (showDate) {
      const timeEl = document.getElementById(DATE_TIME_IDS.timeEl.label);
      const time = timeEl.getAttribute("data-time");
      const dateEl = document.getElementById(DATE_TIME_IDS.dateEl.label);
      const date = dateEl.getAttribute("data-date");
      title = `${text} ${time}, ${date}`;
    }
    const accordionTitle = document.getElementById("trip-plan-accordion-title");
    accordionTitle.innerHTML = title;
    accordionTitle.setAttribute("data-prefix", text);
  }

  static reverseTrip() {
    return () => {
      const $ = window.jQuery;
      let from = $("#from").val();
      let to = $("#to").val();
      let fromLat = $("#from_latitude").val();
      let fromLng = $("#from_longitude").val();
      let toLat = $("#to_latitude").val();
      let toLng = $("#to_longitude").val();
      $("#from_latitude").val(toLat);
      $("#from_longitude").val(toLng);
      $("#to_latitude").val(fromLat);
      $("#to_longitude").val(fromLng);
      $("#from").val(to);
      $("#to").val(from);
    }
  }
}

export function init() {
  const $ = window.jQuery;
  const tripPlanner = new TripPlan();
  $(document).on("turbolinks:load", () => {
    $(".itinerary-alert-toggle").show();
    $(".itinerary-alert-toggle").trigger("click");
    $("#trip-plan-datepicker").hide();
    if (document.getElementById(DATE_TIME_IDS.dateEl.input)) {
      $("#trip-plan-accordion-title").data("prefix", "Leave now");
      tripPlanner.dateInput($);
      TripPlan.timeInput($);
      TripPlan.doUpdateAccordionTitle("Leave now", false);
    }
  });
  return tripPlanner;
}

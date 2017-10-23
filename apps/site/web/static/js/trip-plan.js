import { getZoom, triggerResize } from "./google-map";

export default function tripPlan($ = window.jQuery) {
  $(document).on("geolocation:complete", "#to", geolocationCallback($));
  $(document).on("geolocation:complete", "#from", geolocationCallback($));
  $(document).on("focus", "#to.trip-plan-current-location", highlightCurrentLocation($));
  $(document).on("focus", "#from.trip-plan-current-location", highlightCurrentLocation($));
  $(document).on("input", "#to.trip-plan-current-location", clearCurrentLocation($));
  $(document).on("input", "#from.trip-plan-current-location", clearCurrentLocation($));
  $("[data-planner-body]").on("hide.bs.collapse", toggleIcon);
  $("[data-planner-body]").on("show.bs.collapse", toggleIcon);
  $("[data-planner-body]").on("shown.bs.collapse", redrawMap);
  $(".itinerary-alert-toggle").on("click", toggleAlertDropdownText);
  $(document).on("turbolinks:load", function() {
    $(".itinerary-alert-toggle").show();
    $(".itinerary-alert-toggle").trigger('click');
    if (document.getElementById(DATE_TIME_IDS.dateEl.input)) {
      dateInput($);
      timeInput($);
    }
  });
};

export const DATE_TIME_IDS = {
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
    link: "plan-date-link"
  },
  timeEl: {
    container: "plan-time",
    select: "plan-time-select",
    link: "plan-time-link"
  }
}

export function dateInput($) {
  const $dateContainer = $("#" + DATE_TIME_IDS.dateEl.container);
  const $dateInput = $("#" + DATE_TIME_IDS.dateEl.input);
  const $dateSelect = $("#" + DATE_TIME_IDS.dateEl.select);
  const $dateLink = $("#" + DATE_TIME_IDS.dateEl.link);
  const actualMonth = parseInt(document.getElementById(DATE_TIME_IDS.month).value);
  const minAllowedDate = $dateInput.data('min-date');
  const maxAllowedDate = $dateInput.data('max-date');
  const date = new Date(document.getElementById(DATE_TIME_IDS.year).value, actualMonth - 1, document.getElementById(DATE_TIME_IDS.day).value);

  $dateInput.val(getFriendlyDate(date));

  $dateInput.datepicker({outputFormat: 'MM/dd/yyyy',
                         onUpdate: updateDate.bind(this, $),
                         min: minAllowedDate,
                         max: maxAllowedDate
  });

  // disable clicking on the month to change the grid type
  $(".datepicker-month").off();

  // remove fast-skip buttons
  $(".datepicker-month-fast-next").remove();
  $(".datepicker-month-fast-prev").remove();

  // replace default datepicker arrow icons
  $(".datepicker-calendar").find(".glyphicon").removeClass("glyphicon").addClass("fa")
  $(".datepicker-calendar").find(".glyphicon-triangle-right").removeClass("glyphicon-triangle-right").addClass("fa-caret-right");
  $(".datepicker-calendar").find(".glyphicon-triangle-left").removeClass("glyphicon-triangle-left").addClass("fa-caret-left");
  $(".datepicker-calendar").on("ab.datepicker.closed", function(ev) {
    $dateLink.fadeIn();
  });
  $(document).on("click", "#" + DATE_TIME_IDS.dateEl.link, (ev) => {
    ev.preventDefault();
    ev.stopPropagation();
    $("#" + DATE_TIME_IDS.dateEl.input).datepicker("show");
  });

  $dateSelect.hide();
  $dateInput.datepicker("setDate", date);
  $dateInput.datepicker("update");
}

export function getFriendlyDate(date) {
  const options = {weekday: "long",
                   year: "numeric",
                   month: "long",
                   day: "numeric"}
  return date.toLocaleDateString("en-US", options);
}

export function getFriendlyTime(datetime) {
  let amPm = "AM";
  let hour = datetime.getHours();
  let minute = datetime.getMinutes();

  if (hour > 11) { amPm = "PM"; }
  if (hour > 12) { hour -= 12; }
  if (hour === 0) { hour = 12; }

  if (minute < 10) { minute = `0${minute}`; }

  return `${hour}:${minute} ${amPm}`
}

function updateDate($, newDate) {
  const date = new Date(newDate);
  const month = date.getMonth() + 1;
  document.getElementById(DATE_TIME_IDS.dateEl.link).textContent = getFriendlyDate(date);
  updateDateSelect($, "#" + DATE_TIME_IDS.year, date.getFullYear().toString());
  updateDateSelect($, "#" + DATE_TIME_IDS.month, month.toString());
  updateDateSelect($, "#" + DATE_TIME_IDS.day, date.getDate().toString());
  $("#" + DATE_TIME_IDS.dateEl.input).datepicker("hide");
  $("#" + DATE_TIME_IDS.dateEl.link).show();
}

function updateDateSelect($, selector, newValue) {
  const currentOpt = $(selector).find("option[selected='selected']");
  const newOpt = $(selector).find(`option[value=${newValue}]`);
  currentOpt.removeAttr("selected");
  if (newOpt.length === 0) {
    currentOpt.parent().append($(`<option value="${newValue}" selected="selected">${newValue}</option>`));
  } else {
    newOpt.attr("selected", "selected");
  }
}

export function timeInput($) {
  document.getElementById(DATE_TIME_IDS.timeEl.link).addEventListener("click", showTimeSelectors, true);
  $(".datepicker-calendar").on("ab.datepicker.closed", updateTime);
}

function showTimeSelectors(ev) {
  ev.preventDefault();
  document.addEventListener("click", handleClickOutsideTime, true);
  const link = document.getElementById(DATE_TIME_IDS.timeEl.link)
  document.getElementById(DATE_TIME_IDS.timeEl.select).style.display = window.getComputedStyle(link).display;
  link.style.display = "none";
  return false;
}

function showTimeLink(ev) {
  document.removeEventListener("click", handleClickOutsideTime, true);
  updateTime();
  const selects = document.getElementById(DATE_TIME_IDS.timeEl.select);
  document.getElementById(DATE_TIME_IDS.timeEl.link).style.display = window.getComputedStyle(selects).display;
  selects.style.display = "none";
  return true;
}

function updateTime() {
  const time = new Date();
  const hour12 = parseInt(document.getElementById(DATE_TIME_IDS.hour).value) % 12
  const amPm = document.getElementById(DATE_TIME_IDS.amPm).value
  const hour = amPm == "PM" ? hour12 + 12 : hour12;
  time.setHours(hour);
  time.setMinutes(document.getElementById(DATE_TIME_IDS.minute).value);
  document.getElementById(DATE_TIME_IDS.timeEl.link).textContent = getFriendlyTime(time);
}

function handleClickOutsideTime(ev) {
  if (ev.target.id == DATE_TIME_IDS.hour || ev.target.id == DATE_TIME_IDS.minute || ev.target.id == DATE_TIME_IDS.amPm) {
    return false;
  } else {
    showTimeLink(ev);
  }
}

export function geolocationCallback($) {
  return function (e, location) {
    const targets = targetFields($, e);
    targets.latitude.val(location.coords.latitude);
    targets.longitude.val(location.coords.longitude);

    const $activeField = $(e.target);
    $activeField.val("Your current location");
    $activeField.addClass("trip-plan-current-location");
  };
}

function targetFields($, e) {
  const fieldName = e.target.name;
  const baseName = /\[(\w+)\]/.exec(fieldName)[1];
  return {
    latitude: $(`[name='plan[${baseName}_latitude]']`),
    longitude: $(`[name='plan[${baseName}_longitude]']`)
  };
}

function highlightCurrentLocation($) {
  return function(e) {
    const $field = $(e.target);
    $field.select();
  };
}

function clearCurrentLocation($) {
  return function(e) {
    const $field = $(e.target);
    $field.removeClass("trip-plan-current-location");
    if ($field.val().length > 1) {
      $field.val("");
    }

    const targets = targetFields($, e);
    targets.latitude.val("");
    targets.longitude.val("");
  };
}

function collapseItineraries($) {
  return function(e) {
    $("[data-planner-body]").addClass("collapse");
  };
}

// Toggles the arrow icon
function toggleIcon(e) {
  const container = $(e.target).parent();
  const icon = $(container).find("[data-planner-header] i");
  icon.toggleClass("fa-plus-circle fa-minus-circle");
}

// There is a race condition that sometimes occurs on the initial render of the google map. It can't render properly
// because it's container is being resized. This function is called after an itinerary is expanded to redraw the map
// if necessary.
function redrawMap(e) {
  const container = $(e.target).parent();
  const offset = $(container).find(".trip-plan-itinerary-body").attr("data-offset");
  const zoom = getZoom(offset);
  triggerResize(offset);
}

function toggleAlertDropdownText(e) {
  var target = $(e.target);
  if(target.text() == "(view alert)") {
    target.text("(hide alert)");
  } else {
    target.text("(view alert)");
  }
}

import { getZoom, triggerResize } from "./google-map";

export default function tripPlan($ = window.jQuery) {
  $(document).on("geolocation:complete", "#to", geolocationCallback($));
  $(document).on("geolocation:complete", "#from", geolocationCallback($));
  $(document).on("focus", "#to.trip-plan-current-location", clearCurrentLocation($));
  $(document).on("focus", "#from.trip-plan-current-location", clearCurrentLocation($));
  $("[data-planner-body]").on("hide.bs.collapse", toggleIcon);
  $("[data-planner-body]").on("show.bs.collapse", toggleIcon);
  $("[data-planner-body]").on("shown.bs.collapse", redrawMap);
  $(".itinerary-alert-toggle").on("click", toggleAlertDropdownText);
  $(document).on("turbolinks:load", function() {
    $(".itinerary-alert-toggle").show();
    $(".itinerary-alert-toggle").trigger('click');
  });

  if ($.fn.datepicker) {
    // currently $.datepicker isn't accessible to js tests since it's in vendor
    // and gets concatenated to app.js by Brunch; running this conditionally
    // just hides it from the js tests so that they're able to pass.
    dateInput($);
  }
};

function getFriendlyDate(date) {
  const dayOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][date.getDay()];
  const month = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
                 "November", "December"][date.getMonth()];
  const dayNumber = date.getDate();
  return `${dayOfWeek}, ${month} ${dayNumber}`;
}

function parseDateString(dateText) {
  const parts = dateText.replace(" ", "").split("/");
  return new Date(parts[2], (parts[0] - 1), parts[1]);
}

function dateInput($) {
  const $dateInputContainer = $("#plan-date-container");
  const $dateInput = $("#plan-date");
  const $dateLink = $("#plan-date-link");
  const now = new Date();

  // hide input box and show date link (hiding calendar is handled elsewhere)
  const showDateLink = (ev) => {
    const newDate = $dateInput.datepicker("getDate");
    $dateInput.datepicker("setDate", newDate);
    $dateLink.text(getFriendlyDate(newDate));
    $dateInputContainer.css({display: "none"});
    $dateLink.css({display: "inline-block"});
  }

  // hide date link, show input box and calendar
  const showCalendar = () => {
    $dateLink.css({display: "none"});
    $dateInputContainer.css({display: "inline-block"});
    $dateInput.datepicker("show");
  }

  // put current date in date link
  $dateLink.text(getFriendlyDate(now));

  // convert date input into an accessible date picker
  $dateInput.datepicker({outputFormat: 'MM / dd / yyyy'});
  $dateInput.datepicker("setDate", now);

  // handle user direct toggle of date link to date input
  $dateLink.click((ev) => {
    ev.preventDefault();
    ev.stopPropagation();
    showCalendar();
  });

  // detect calendar close event and optionally display date link
  $(".datepicker-calendar").on("ab.datepicker.closed", showDateLink);

  // detect date input blurred, show date link
  $dateInput.blur((e) => {
    const dateText = $dateInput.val();
    const newDate = parseDateString(dateText);
    $dateLink.text(getFriendlyDate(newDate));
    showDateLink();
  });
}

export function geolocationCallback($) {
  return function (e, location) {
    const targets = targetFields($, e);
    targets.latitude.val(location.coords.latitude);
    targets.longitude.val(location.coords.longitude);

    const $activeField = $(e.target);
    $activeField.val("Current Location");
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

function clearCurrentLocation($) {
  return function(e) {
    const $field = $(e.target);
    $field.removeClass("trip-plan-current-location");
    $field.val("");

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
  icon.toggleClass("fa-caret-down fa-caret-up");
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

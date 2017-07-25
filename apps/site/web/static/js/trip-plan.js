import { initializeMap, getZoom } from './google-map';

export default function tripPlan($ = window.jQuery) {
  hideHiddenSteps($);
  $(document).on('geolocation:complete', '#to', geolocationCallback($));
  $(document).on('geolocation:complete', '#from', geolocationCallback($));
  $(document).on("focus", "#to.trip-plan-current-location", clearCurrentLocation($));
  $(document).on("focus", "#from.trip-plan-current-location", clearCurrentLocation($));
  $("[data-planner-body]").on('hide.bs.collapse', toggleIcon);
  $("[data-planner-body]").on('show.bs.collapse', toggleIcon);
  $("[data-planner-body]").on('shown.bs.collapse', redrawMap);
  window.addEventListener("load", collapseItineraries($));
  $("[data-reveal-step-button]").on("click", revealSteps);
};

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
    $("[data-planner-body]").each(function (offset, el) {
      $(el).addClass("collapse").attr("data-offset", offset);
    });
  };
}

// Toggles the arrow icon
function toggleIcon(e) {
  const container = $(e.target).parent();
  const icon = $(container).find("[data-planner-header] i");
  icon.toggleClass("fa-caret-down fa-caret-up");
}

// There is a race condition that sometimes occurs on the intial render of the google map where it can't set up
// it canvas properly because it is not sure of its dimensions because it is doing the calculation while it's container
// is being collapsed. This function will be called after an itenary is expanded to redraw the map
function redrawMap(e) {
  // only when the zoom value is very low does the map will need to be re-rendered
  const container = $(e.target).parent();
  const offset = $(container).find(".trip-plan-itinerary-body").attr("data-offset");
  const zoom = getZoom(offset);
  if (zoom > 5) {
    return;
  }
  const mapData = JSON.parse($(container).find(".dynamic_map_data")[0].innerHTML);
  const mapEl = $(container).find(".dynamic-map")[0];
  initializeMap(mapEl, mapData, offset);
}

function revealSteps(e) {
  const parent = $(e.target).closest(".itinerary-row-container");
  parent.find("[data-hidden-step]").slideToggle();
  $(e.target).closest(".route-branch-stop").hide();
  parent.find("[data-before-reveal-button] .route-branch-stop-bubble-line").removeClass("dotted").addClass("solid");
}

function hideHiddenSteps($) {
  const hiddenSteps = $("[data-hidden-step]");
  if (hiddenSteps.length > 0) {
    hiddenSteps.hide();
    $("[data-before-reveal-button]").find(".route-branch-stop-bubble-line").removeClass("solid").addClass("dotted");
  }
}

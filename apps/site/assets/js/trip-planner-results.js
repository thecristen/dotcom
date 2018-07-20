import { triggerResize } from "./google-map";

export class TripPlannerResults {
  constructor() {
    $("[data-planner-body]").on("hide.bs.collapse", this.toggleIcon);
    $("[data-planner-body]").on("show.bs.collapse", this.toggleIcon);
    $("[data-planner-body]").on("shown.bs.collapse", this.redrawMap);
    $(".itinerary-alert-toggle").on("click", this.toggleAlertDropdownText);
    if (navigator.userAgent.search("Firefox") > 0) {
      // We only want to load map images if they're actually being // used, to avoid spending money unnecessarily.
      // Normally, that's accomplished by using background-image: url(); however, Firefox hides background images by
      // default in printouts. This is a hack to load the static map image on Firefox only when javascript is enabled
      // and the user has requested to print the page. The image is only visible under the @media print query, so
      // it does not need to be removed after printing.
      window.addEventListener("beforeprint", this.firefoxPrintStaticMap);
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

  toggleAlertDropdownText(e) {
    const target = $(e.target);
    if (target.text() === "(view alert)") {
      target.text("(hide alert)");
    } else {
      target.text("(view alert)");
    }
  }

  toggleIcon(e) {
    const container = $(e.target).parent();
    const icon = $(container).find("[data-planner-header] i");
    icon.toggleClass("fa-plus-circle fa-minus-circle");
  }

  // There is a race condition that sometimes occurs on the initial render of the google map. It can't render properly
  // because it's container is being resized. This function is called after an itinerary is expanded to redraw the map
  // if necessary.
  redrawMap(e) {
    const container = $(e.target).parent();
    const el = $(container).find(".trip-plan-itinerary-body .map-dynamic")[0];
    triggerResize(el);
  }

  firefoxPrintStaticMap() {
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
}

export function init() {
  const $ = window.jQuery;
  const results = new TripPlannerResults();
  $(document).on("turbolinks:load", () => {
    $(".itinerary-alert-toggle").show();
    $(".itinerary-alert-toggle").trigger("click");
  });
  return results;
}

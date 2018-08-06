import { doWhenGoogleMapsIsReady } from "./google-maps-loaded";
import GoogleMap from "./google-map-class";

export class TripPlannerResults {
  constructor() {
    this.maps = {};
    this.bind();
    this.addEventListeners();

    this.initMaps();

    $("[data-planner-body]").on("hide.bs.collapse", this.toggleIcon);
    $("[data-planner-body]").on("show.bs.collapse", this.toggleIcon);
    $("[data-planner-body]").on("shown.bs.collapse", this.resetMapBounds);
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

  bind() {
    this.initMap = this.initMap.bind(this);
    this.onUpdateMarker = this.onUpdateMarker.bind(this);
    this.onRemoveMarker = this.onRemoveMarker.bind(this);
    this.resetMapBounds = this.resetMapBounds.bind(this);
  }

  addEventListeners() {
    const $ = window.jQuery;
    $(document).on("trip-plan:update-marker", this.onUpdateMarker);
    $(document).on("trip-plan:remove-marker", this.onRemoveMarker);
  }

  initMaps() {
    const dataEls = document.getElementsByClassName(
      "js-trip-plan-map-dynamic-data"
    );
    Array.from(dataEls).forEach(this.initMap);
  }

  initMap(dataEl) {
    const id = dataEl.getAttribute("data-for");
    const data = JSON.parse(dataEl.innerHTML);
    this.maps[id] = new GoogleMap(id, data);
  }

  initialMap() {
    return this.maps["trip-plan-map--initial"];
  }

  onUpdateMarker(ev, { detail }) {
    const map = this.initialMap();
    if (map && detail.latitude && detail.longitude) {
      const id = `marker-${detail.label}`;
      const markerData = {
        id: id,
        latitude: detail.latitude,
        longitude: detail.longitude,
        tooltip: detail.title,
        size: "large",
        icon: "map-pin",
        label: {
          color: "#fff",
          font_size: "22px",
          font_weight: "bold",
          text: detail.label,
          font_family: "Helvetica Neue, Helvetica, Arial"
        },
        "visible?": true
      };
      map.addOrUpdateMarker(markerData);
      this.updateMapCenter(map);
    }
  }

  onRemoveMarker(ev, { detail }) {
    const map = this.initialMap();
    if (map) {
      map.removeMarker(`marker-${detail.label}`);
      this.updateMapCenter(map);
      this.updateMapZoom(map);
    }
  }

  updateMapCenter(map) {
    if (map) {
      switch (map.visibleMarkers().length) {
        case 0:
        case 1:
          map.addCenterToBounds();
          break;

        default:
          map.removeCenterFromBounds();
      }
    }
  }

  updateMapZoom(map) {
    if (map && map.visibleMarkers().length === 0) {
      map.resetZoom();
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

  resetMapBounds(ev) {
    // There is a race condition that sometimes occurs on the initial render of the google map. It can't render properly
    // because it's container is being resized. This function is called after an itinerary is expanded to redraw the map
    // if necessary.
    const $ = window.jQuery;
    const id = $(ev.target)
      .parents(".trip-plan-itinerary-container")
      .find(".js-google-map")
      .attr("id");

    if (this.maps[id]) {
      this.maps[id].panToBounds();
    }
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
  $(document).on("turbolinks:load", () => {
    $(".itinerary-alert-toggle").show();
    $(".itinerary-alert-toggle").trigger("click");
    doWhenGoogleMapsIsReady(() => new TripPlannerResults());
  });
}

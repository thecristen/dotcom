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
}

export function init() {
  const $ = window.jQuery;
  $(document).on("turbolinks:load", () => {
    $(".itinerary-alert-toggle").show();
    $(".itinerary-alert-toggle").trigger("click");
    doWhenGoogleMapsIsReady(() => new TripPlannerResults());
  });
}

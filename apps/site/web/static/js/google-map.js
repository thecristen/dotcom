export default function() {
  function initMap() {
    // Read the map data from page
    var mapDataElements = document.getElementsByClassName("dynamic_map_data");

    // Clean up and leave if there is no map data available
    if (!mapDataElements || mapDataElements.length == 0) {
      // Get rid of any previously registered reavaluteMapBounds event
      window.removeEventListener("resize", reavaluteMapBounds);
      return;
    }

    // Render all maps by iterating over the HTMLCollection elements
    const mapElements = document.getElementsByClassName("dynamic-map");
    for (var i = 0; i < mapElements.length; i++) {
      var mapData = JSON.parse(mapDataElements[i].innerHTML)
      initializeMap(mapElements[i], mapData, i);
    }

    // Reconsier bounds on page resize
    window.addEventListener("resize", reavaluteMapBounds);
  }

  document.addEventListener("turbolinks:load", initMap, {passive: true});
}

// These values are global to this module
var maps = {};
var bounds = {};
var infoWindow = null;
var markers = {};

function initializeMap(el, mapData, offset) {
  if (typeof google != "undefined") {
    el.className += " google-map";
    displayMap(el, mapData, offset);
  } else {
    const existingCallback = window.mapsCallback || function() {};
    window.mapsCallback = function() {
      window.mapsCallback = undefined;
      existingCallback();
      initializeMap(el, mapData, offset);
    };
  }
}

function displayMap(el, mapData, mapOffset) {
  // Create a map instance
  maps[mapOffset] = new google.maps.Map(el, mapData.dynamic_options);

  // Bounds will allow us to later zoom the map to the boundaries of the stops
  bounds[mapOffset] = new google.maps.LatLngBounds();

  // If there are stops, show them
  if (mapData.markers) {
    mapData.markers.forEach(renderMarker(mapOffset));
  }

  // If there are route polylines, show them
  if (mapData.paths) {
    renderPolylines(mapOffset, mapData.paths);
  }

  // Auto zoom and auto center
  maps[mapOffset].fitBounds(bounds[mapOffset]);
  maps[mapOffset].panToBounds(bounds[mapOffset]);

  // If the map zooms in too much, take it out to a reasonble level
  const zoom = maps[mapOffset].getZoom();
  if (!zoom) {
    google.maps.event.addListenerOnce(maps[mapOffset], "zoom_changed", function() {
      setReasonableZoom(maps[mapOffset], maps[mapOffset].getZoom());
    });
  } else {
    setReasonableZoom(maps[mapOffset], zoom);
  }

  // Don't show points of interest
  maps[mapOffset].setOptions({styles: [{featureType: "poi", stylers: [{visibility: "off"}]}]});
}

function renderPolylines (mapOffset, polylines) {
  polylines.forEach((path) => {
    new google.maps.Polyline({
      path: google.maps.geometry.encoding.decodePath(path.polyline),
      geodesic: true,
      strokeColor: "#" + path.color,
      strokeOpacity: 1.0,
      strokeWeight: path.weight
    }).setMap(maps[mapOffset]);
  });
}

function renderMarker (mapOffset) {
  return (markerData, offset) => {
    var lat = markerData.latitude;
    var lng = markerData.longitude;
    var content = markerData.tooltip;
    var key = markerData.z_index + offset;
    var iconSize = markerData.size == "tiny" ? 8 : 16;
    var icon = buildIcon(markerData.icon, iconSize);

    // Add a marker to map
    if (markerData["visible?"]) {
      markers[key] = new google.maps.Marker({
        position: {lat: lat, lng: lng},
        map: maps[mapOffset],
        icon: icon,
        zIndex: markerData.z_index + offset
      });

      // Display information about
      if (content) {
        markers[key].addListener("mouseover", showInfoWindow(maps[mapOffset], markers[key], content));
        markers[key].addListener("mouseout", () => { closeInfoWindow(); });
      }
    }

    // Extend the boundaries of the map to include this marker
    bounds[mapOffset].extend(new google.maps.LatLng(lat, lng));
  }
}

// When there are very few markers, map will zoom in too close. 17 is a reasonable zoom level to see a small
// number of points with additional contextual nearby map imagery
function setReasonableZoom(map, zoom) {
  if (zoom > 17) {
    map.setZoom(17);
  }
}

// Return a callback that can open an info window with specific content
function showInfoWindow(map, marker, content) {
  return (input) => {
    // If another info window is displayed, close it
    if (infoWindow) {
      closeInfoWindow();
    }
    infoWindow = new google.maps.InfoWindow({content: content});
    infoWindow.open(map, marker);
  }
}

function closeInfoWindow() {
  infoWindow.close();
}

// If the map container size changes, recalulate the positioning of the map contents
function reavaluteMapBounds () {
  for (var offset in maps) {
    maps[offset].fitBounds(bounds[offset]);
    maps[offset].panToBounds(bounds[offset]);
  }
}

// If there is icon data, return an icon, otherwise return null
function buildIcon(iconData, iconSize) {
  if (iconData) {
    return {
      url: iconData,
      size: new google.maps.Size(iconSize, iconSize),
      origin: new google.maps.Point(0, 0),
      anchor: new google.maps.Point(iconSize / 2, iconSize / 2)
    };
  } else {
    return null;
  }
}

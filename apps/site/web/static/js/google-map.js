import { doWhenGoogleMapsIsLoaded } from './google-maps-loaded';

export default function($) {
  $ = $ || window.jQuery;

  function initMap() {
    // Read the map data from page
    var mapDataElements = document.getElementsByClassName("dynamic_map_data");

    // Clean up and leave if there is no map data available
    if (!mapDataElements || mapDataElements.length == 0) {
      // Get rid of any previously registered reevaluateMapBounds event
      window.removeEventListener("resize", reevaluateMapBounds);
      return;
    }

    // Render all maps by iterating over the HTMLCollection elements
    const mapElements = document.getElementsByClassName("dynamic-map");
    for (var i = 0; i < mapElements.length; i++) {
      var mapData = JSON.parse(mapDataElements[i].innerHTML);
      mapElements[i].className += " google-map";
      displayMap(mapElements[i], mapData, i);
    }

    // Reconsier bounds on page resize
    window.addEventListener("resize", reevaluateMapBounds);
  }

  doWhenGoogleMapsIsLoaded($, () => {
    document.addEventListener("turbolinks:load", initMap, {passive: true});
    initMap();
  });
}

// These values are global to this module
var maps = {};
var bounds = {};
var infoWindow = null;
var markers = {};

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
  if (mapData.markers.length > 1) {
    maps[mapOffset].fitBounds(bounds[mapOffset]);
    maps[mapOffset].panToBounds(bounds[mapOffset]);
  } else {
    maps[mapOffset].setCenter(bounds[mapOffset].getCenter());
  }

  var mapDataElements = document.getElementsByClassName("dynamic_map_data");

  // If the map zooms in too much, take it out to a reasonble level
  const zoom = maps[mapOffset].getZoom();
  if (!zoom && !mapData.zoom) {
    google.maps.event.addListenerOnce(maps[mapOffset], "zoom_changed", function() {
      setReasonableZoom(maps[mapOffset], maps[mapOffset].getZoom());
    });
  } else if(mapData.zoom) {
    maps[mapOffset].setZoom(mapData.zoom);
  } else {
    setReasonableZoom(maps[mapOffset], zoom);
  }

  // Don't show points of interest
  maps[mapOffset].setOptions({styles: [{featureType: "poi", stylers: [{visibility: "off"}]}]});
}

function renderPolylines (mapOffset, polylines) {
  polylines.forEach((path) => {
    polylineForPath(path).setMap(maps[mapOffset]);
  });
}

function polylineForPath (path) {
  if (path["dotted?"]) {
    const lineSymbol = {
      path: `M 0,-${path.weight} 0,${path.weight}`,
      strokeOpacity: 1,
      scale: 2
    };
    return new google.maps.Polyline({
      icons: [{
        icon: lineSymbol,
        offset: '0',
        repeat: '10px'
      }],
      path: google.maps.geometry.encoding.decodePath(path.polyline),
      geodesic: true,
      strokeOpacity: 0
    })
  } else {
    return new google.maps.Polyline({
      path: google.maps.geometry.encoding.decodePath(path.polyline),
      geodesic: true,
      strokeColor: "#" + path.color,
      strokeOpacity: 1.0,
      strokeWeight: path.weight
    })
  }
}

function renderMarker (mapOffset) {
  return (markerData, offset) => {
    var lat = markerData.latitude;
    var lng = markerData.longitude;
    var content = markerData.tooltip;
    var key = markerData.z_index + offset;
    var iconSize = getIconSize(markerData.size);
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

export function getZoom(mapOffset) {
  return maps[mapOffset].getZoom();
}

export function triggerResize(mapOffset) {
  google.maps.event.trigger(maps[mapOffset], "resize");
  reevaluateMapBound(mapOffset);
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
function reevaluateMapBounds() {
  for (var offset in maps) {
    reevaluateMapBound(offset);
  }
}

function reevaluateMapBound(offset) {
  if (Object.keys(markers).length > 1) {
    maps[offset].fitBounds(bounds[offset]);
    maps[offset].panToBounds(bounds[offset]);
  } else {
    maps[offset].setCenter(bounds[offset].getCenter());
  }
}

// If there is icon data, return an icon, otherwise return null
function buildIcon(iconData, iconSize) {
  if (iconData) {
    return {
      url: "data:image/svg+xml;utf-8, " + iconSvg(iconData),
      size: new google.maps.Size(iconSize, iconSize),
      origin: new google.maps.Point(0, 0),
      anchor: new google.maps.Point(iconSize / 2, iconSize / 2)
    };
  } else {
    return null;
  }
}

function getIconSize(size) {
  switch (size) {
    case "tiny":
      return 8;
      break;
    case "small":
      return 12;
      break;
    default:
      return 22; // "mid" sized
  }
}

export function iconSvg(marker) {
  const parts = marker.split('-');
  const id = parts.shift();
  const type = parts.join('-');

  switch (type) {
    case "dot":
      return iconDot(id);

    case "dot-filled":
      return iconDotFilled(id);

    case "dot-filled-mid":
      return iconDotFilledMid(id);

    case "dot-mid":
      return iconDotMid(id);

    case "vehicle":
      return iconVehicle(id);
  }
}

function iconDot(color) {
  return `<svg width="8" height="8" xmlns="http://www.w3.org/2000/svg"><circle fill="#FFFFFF" cx="4" cy="4" r="3"></circle><path d="M4,6.5 C5.38071187,6.5 6.5,5.38071187 6.5,4 C6.5,2.61928813 5.38071187,1.5 4,1.5 C2.61928813,1.5 1.5,2.61928813 1.5,4 C1.5,5.38071187 2.61928813,6.5 4,6.5 Z M4,8 C1.790861,8 0,6.209139 0,4 C0,1.790861 1.790861,0 4,0 C6.209139,0 8,1.790861 8,4 C8,6.209139 6.209139,8 4,8 Z" fill="#${color}" fill-rule="nonzero"></path></svg>`;
}

function iconDotFilled(color) {
  return `<svg width="8" height="8" xmlns="http://www.w3.org/2000/svg"><circle fill="#000000" cx="4" cy="4" r="3"></circle><path d="M4,6.5 C5.38071187,6.5 6.5,5.38071187 6.5,4 C6.5,2.61928813 5.38071187,1.5 4,1.5 C2.61928813,1.5 1.5,2.61928813 1.5,4 C1.5,5.38071187 2.61928813,6.5 4,6.5 Z M4,8 C1.790861,8 0,6.209139 0,4 C0,1.790861 1.790861,0 4,0 C6.209139,0 8,1.790861 8,4 C8,6.209139 6.209139,8 4,8 Z" fill="#${color}" fill-rule="nonzero"></path></svg>`;
}

function iconDotMid(color) {
  return `<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg"><circle fill="#FFFFFF" cx="8" cy="8" r="7"></circle><path d="M8,13 C10.7614237,13 13,10.7614237 13,8 C13,5.23857625 10.7614237,3 8,3 C5.23857625,3 3,5.23857625 3,8 C3,10.7614237 5.23857625,13 8,13 Z M8,16 C3.581722,16 0,12.418278 0,8 C0,3.581722 3.581722,0 8,0 C12.418278,0 16,3.581722 16,8 C16,12.418278 12.418278,16 8,16 Z" fill="#${color}" fill-rule="nonzero"></path></svg>`;
}

function iconDotFilledMid(color) {
  return `<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg"><circle fill="#000000" cx="8" cy="8" r="7"></circle><path d="M8,13 C10.7614237,13 13,10.7614237 13,8 C13,5.23857625 10.7614237,3 8,3 C5.23857625,3 3,5.23857625 3,8 C3,10.7614237 5.23857625,13 8,13 Z M8,16 C3.581722,16 0,12.418278 0,8 C0,3.581722 3.581722,0 8,0 C12.418278,0 16,3.581722 16,8 C16,12.418278 12.418278,16 8,16 Z" fill="#${color}" fill-rule="nonzero"></path></svg>`;
}

function iconVehicle(type) {
  let path;
  switch (type) {
  case "train":
    path = `M8.083 16.5l-.416.833h-.834l.417-.833h-.255A.992.992 0 0 1 6 15.507v-.097-8.74c0-.554.38-1.235.87-1.503C6.87 5.167 8.5 4 11 4s4.13 1.167 4.13 1.167c.48.276.87.946.87 1.503v8.837a1 1 0 0 1-.995.993h-.255l.417.833h-.834l-.416-.833H8.083zm.417-10c0 .463.37.833.826.833h3.348a.833.833 0 0 0 0-1.666H9.326A.833.833 0 0 0 8.5 6.5zm-1.25.833a.417.417 0 1 0 0-.833.417.417 0 0 0 0 .833zm7.5 0a.417.417 0 1 0 0-.833.417.417 0 0 0 0 .833zm-.417 8.334a.833.833 0 1 0 0-1.667.833.833 0 0 0 0 1.667zm-6.666 0a.833.833 0 1 0 0-1.667.833.833 0 0 0 0 1.667zm-.834-6.5v3a1 1 0 0 0 1.006 1h6.322c.558 0 1.006-.448 1.006-1v-3a1 1 0 0 0-1.006-1H7.84c-.558 0-1.006.447-1.006 1z`;
    break;

  case "cr":
    path = `M6.717 9.08a1.028 1.028 0 0 1-.003-.075V7.423c0-.549.427-1.137.951-1.311l2.384-.795c.525-.175 1.378-.175 1.902 0l2.384.795c.525.175.95.754.95 1.311v1.582c0 .026 0 .05-.002.076l.717.205v4c0 .552-.456 1-.995 1h-8.01a.995.995 0 0 1-.995-1v-4l.717-.205zm7.854 3.777a.714.714 0 1 0 0-1.428.714.714 0 0 0 0 1.428zm-7.142 0a.714.714 0 1 0 0-1.428.714.714 0 0 0 0 1.428zm0-5.714V8.57l2.857-.714V6.43l-2.857.714zm4.285-.714v1.428l2.857.714V7.143l-2.857-.714zM6.714 15h8.572v.357a.36.36 0 0 1-.358.357H7.072a.361.361 0 0 1-.358-.357V15zm2.143.714h1.429l-1.429 1.429H7.43l1.428-1.429zm2.857 0h1.429l1.428 1.429h-1.428l-1.429-1.429z`;
    break;

  case "bus":
    path = `M13.184 15.714H8.815c-.124.413-.51.715-.954.715h-.15a.996.996 0 0 1-.965-.746A1 1 0 0 1 6 14.717v-8.71C6 5.45 6.456 5 6.995 5h8.01c.55 0 .995.455.995 1.007v8.919-.209c0 .464-.323.853-.747.965-.113.43-.507.747-.963.747h-.151a.996.996 0 0 1-.955-.715zm-1.47-7.857v4.286h3.572V7.857h-3.572zm-5 0v4.286h3.572V7.857H6.714zm1.429-2.143v1.429h5.714V5.714H8.143zm5.714 7.857c0 .398.32.715.714.715.398 0 .715-.32.715-.715a.713.713 0 0 0-.715-.714.713.713 0 0 0-.714.714zm-2.143 0c0 .398.32.715.715.715.397 0 .714-.32.714-.715a.713.713 0 0 0-.714-.714.713.713 0 0 0-.715.714zm-2.857 0c0 .398.32.715.714.715.398 0 .715-.32.715-.715a.713.713 0 0 0-.715-.714.713.713 0 0 0-.714.714zm-2.143 0c0 .398.32.715.715.715.397 0 .714-.32.714-.715a.713.713 0 0 0-.714-.714.713.713 0 0 0-.715.714z`;
  }

  return `<svg width="22" height="22" xmlns="http://www.w3.org/2000/svg"><g><circle fill="#FFF" cx="11" cy="11" r="11"></circle><g fill="#1C1E23"><path d="${path}"></path></g><path d="M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16zm0 3C4.925 22 0 17.075 0 11S4.925 0 11 0s11 4.925 11 11-4.925 11-11 11z" fill="#1C1E23" fill-rule="nonzero"></path></g></svg>`;
}

export function lookupPlace(placeId) {
  const places = new google.maps.places.PlacesService(document.createElement("div"));
  return new Promise((resolve, reject) => {
    places.getDetails({
      placeId: placeId
    }, processPlacesCallback(resolve, reject))
  });
}

export function reverseGeocode(latitude, longitude) {
  const geocoder = new google.maps.Geocoder;
  return new Promise((resolve, reject) => {
    geocoder.geocode({
      location: {
        lat: latitude,
        lng: longitude
      }
    }, processGeocodeCallback(resolve, reject));
  });
}

function processGeocodeCallback(resolve, reject) {
  return (results, status) => {
    if (status != "OK") {
      reject(status);
    } else {
      if (results[0]) {
        resolve(results[0].formatted_address);
      }
    }
  }
}

function processPlacesCallback(resolve, reject) {
  return (place, status) => {
    if (status != google.maps.places.PlacesServiceStatus.OK) {
      reject(status);
    } else {
      resolve(place);
    }
  }
}

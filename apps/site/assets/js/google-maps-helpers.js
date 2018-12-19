export function autocomplete({
  input,
  searchBounds,
  hitLimit,
  sessionToken,
  service
}) {
  if (input.length === 0) {
    return Promise.resolve({});
  }

  return new Promise((resolve, reject) => {
    // service can be stubbed in tests
    const autocompleteService =
      service || new window.google.maps.places.AutocompleteService();

    autocompleteService.getPlacePredictions(
      {
        input,
        sessionToken,
        bounds: new window.google.maps.LatLngBounds(
          new window.google.maps.LatLng(searchBounds.west, searchBounds.north),
          new window.google.maps.LatLng(searchBounds.east, searchBounds.south)
        )
      },
      processAutocompleteResults(resolve, reject, hitLimit)
    );
  });
}

function processAutocompleteResults(resolve, reject, hitLimit) {
  return (predictions, status) => {
    const results = {
      locations: {
        hits: [],
        nbHits: 0
      }
    };
    if (status != window.google.maps.places.PlacesServiceStatus.OK) {
      return resolve(results);
    }
    results.locations = {
      hits: predictions.slice(0, hitLimit),
      nbHits: predictions.length
    };
    return resolve(results);
  };
}

export function lookupPlace(placeId, sessionToken, service) {
  const places =
    service ||
    new window.google.maps.places.PlacesService(document.createElement("div"));

  const fields = ["formatted_address", "geometry"];

  return new Promise((resolve, reject) => {
    places.getDetails(
      {
        placeId,
        sessionToken,
        fields
      },
      processPlacesCallback(resolve, reject)
    );
  });
}

export function reverseGeocode(latitude, longitude) {
  const geocoder = new google.maps.Geocoder();
  return new Promise((resolve, reject) => {
    geocoder.geocode(
      {
        location: {
          lat: latitude,
          lng: longitude
        }
      },
      processGeocodeCallback(resolve, reject)
    );
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
  };
}

function processPlacesCallback(resolve, reject) {
  return (place, status) => {
    if (status != window.google.maps.places.PlacesServiceStatus.OK) {
      reject(status);
    } else {
      resolve(place);
    }
  };
}

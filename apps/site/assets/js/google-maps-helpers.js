export function autocomplete(query, searchBounds, hitLimit) {
  if (query.length == 0) {
    return Promise.resolve({});
  } else {
    return new Promise((resolve, reject) => {
      new google.maps.places.AutocompleteService().getPlacePredictions(
        {
          input: query,
          bounds: new google.maps.LatLngBounds(
            new google.maps.LatLng(searchBounds.west, searchBounds.north),
            new google.maps.LatLng(searchBounds.east, searchBounds.south)
          )
        },
        processAutocompleteResults(resolve, reject, hitLimit)
      );
    });
  }
}

function processAutocompleteResults(resolve, reject, hitLimit) {
  return (predictions, status) => {
    const results = {
      locations: {
        hits: [],
        nbHits: 0
      }
    };
    if (status != google.maps.places.PlacesServiceStatus.OK) {
      return resolve(results);
    }
    results.locations = {
      hits: predictions.slice(0, hitLimit),
      nbHits: predictions.length
    };
    return resolve(results);
  };
}

export function lookupPlace(placeId) {
  const places = new google.maps.places.PlacesService(
    document.createElement("div")
  );
  return new Promise((resolve, reject) => {
    places.getDetails(
      {
        placeId: placeId
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
    if (status != google.maps.places.PlacesServiceStatus.OK) {
      reject(status);
    } else {
      resolve(place);
    }
  };
}

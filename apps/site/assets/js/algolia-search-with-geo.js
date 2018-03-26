import { Algolia } from './algolia-search';

export class AlgoliaWithGeo extends Algolia {
  constructor(indices, defaultParams, bounds) {
    super(indices, defaultParams);
    this._googleAutocomplete = new google.maps.places.AutocompleteService();
    this._bounds = bounds;
  }

  _doSearch(allQueries) {
    const algoliaResults = this._client.search(allQueries)
                               .then(this._processAlgoliaResults())
                               .catch(err => console.error(err));
    const googleResults = this._doGoogleAutocomplete(this._currentQuery)
                              .catch(() => console.error("Error while contacting google places API."));
    return Promise.all([algoliaResults, googleResults])
                  .then(resultsList => this.updateWidgets(resultsList.reduce((acc, res) => Object.assign(acc, res))))
                  .catch(err => console.error(err));
  }

  _doGoogleAutocomplete(query) {
    if (query.length == 0) {
      return Promise.resolve({});
    } else {
      return new Promise((resolve, reject) => {
        this._googleAutocomplete.getPlacePredictions({
          input: this._currentQuery,
          bounds: new google.maps.LatLngBounds(
            new google.maps.LatLng(this._bounds.west, this._bounds.north),
            new google.maps.LatLng(this._bounds.east, this._bounds.south)
          ),
        }, this._processAutocompleteResults(resolve, reject));
      });
    }
  }

  _processAutocompleteResults(resolve, reject) {
    return (predictions, status) => {
      const results = {};
      if (status != google.maps.places.PlacesServiceStatus.OK) {
        return reject(results);
      }
      results.locations = predictions;
      return resolve(results);
    }
  }
}

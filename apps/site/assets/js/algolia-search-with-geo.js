import { Algolia } from './algolia-search';

export class AlgoliaWithGeo extends Algolia {
  constructor(indices, defaultParams, bounds) {
    super(indices, defaultParams);
    this._googleAutocomplete = new google.maps.places.AutocompleteService();
    this._bounds = bounds;
    this._locationEnabled = true;
  }

  /*
   * Writing a comment because this logic is confusing:
   * Here is the table of when things should be disabled
   * or enabled based on the state of things
   *
   * loc_enabled | activeQueryIds len > 0 | enableLocation | enableAlgolia
   * true          true                    true             true
   * true          false                   true             false
   * false         false                   true             true
   * false         true                    false            true
   */
  _doSearch(allQueries) {
    let algoliaResults = {};
    let googleResults = {};
    if (!(this._locationEnabled && this._activeQueryIds.length == 0)) {
      algoliaResults = this._client.search(allQueries)
                           .then(this._processAlgoliaResults())
                           .catch(err => console.error(err));
    }

    if (!(!this._locationEnabled && this._activeQueryIds.length > 0)) {
      googleResults = this._doGoogleAutocomplete(this._currentQuery)
                          .catch(() => console.error("Error while contacting google places API."));
    }

    return Promise.all([algoliaResults, googleResults]).then(resultsList => {
      this.updateWidgets(resultsList.reduce((acc, res) => {
        return Object.assign(acc, res);
      }));
    }).catch(err => console.error(err));
  }

  resetSearch() {
    super.resetSearch();
    this._locationEnabled = true;
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
      results.locations = {
        hits: predictions,
        nbHits: predictions.length
      };
      return resolve(results);
    }
  }

  enableLocationSearch(enabled) {
    this._locationEnabled = enabled;
  }
}

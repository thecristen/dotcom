import { Algolia } from './algolia-search';
import * as GoogleMapsHelpers from './google-maps-helpers'

export class AlgoliaWithGeo extends Algolia {
  constructor(indices, defaultParams, bounds, hitLimit) {
    super(indices, defaultParams);
    this._bounds = bounds;
    this._locationEnabled = true;
    this._hitLimit = hitLimit ? hitLimit : 5;
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
      algoliaResults = this._sendQueries(allQueries)
                           .then(this._processAlgoliaResults())
                           .catch(err => console.error(err));
    }

    if (!(!this._locationEnabled && this._activeQueryIds.length > 0)) {
      googleResults = GoogleMapsHelpers.autocomplete(this._lastQuery, this._bounds, this._hitLimit)
                          .catch(() => console.error("Error while contacting google places API."));
    }

    return Promise.all([algoliaResults, googleResults]).then(resultsList => {
      this.updateWidgets(resultsList.reduce((acc, res) => {
        return Object.assign(acc, res);
      }));
    }).catch(err => console.error(err));
  }

  reset() {
    super.reset();
    this._locationEnabled = false;
  }

  enableLocationSearch(enabled) {
    this._locationEnabled = enabled;
  }
}

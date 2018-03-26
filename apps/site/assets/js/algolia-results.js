import hogan from 'hogan.js';
import * as AlgoliaResult from "./algolia-result";

const TEMPLATES = {
  contentResults: hogan.compile(`
    <div class="c-search-results__section">
      {{#hasHits}}
        <div class="c-search-result__header">{{title}}</div>
        {{{hits}}}
      {{/hasHits}}
    </div>
 `),
};

export class AlgoliaResults {
  constructor(id) {
    this._id = id
    this._container = document.getElementById(this._id);
    if (!this._container) {
      console.error(`could not find results container with id: ${this._id}`);
    }
  }

  _renderIndex(results, index) {
    if (results[index]) {
      return TEMPLATES.contentResults.render({
        title: AlgoliaResults.indexTitles[index] || "",
        nbHits: results[index].nbHits,
        hasHits: results[index].nbHits > 0,
        hits: results[index].hits.slice(0)
                                 .map(this.renderResult(index))
                                 .join("")
      });
    }
    return "";
  }

  init() {
  }

  render(results)  {
    if (this._container) {
      this._container.innerHTML =
        ["routes", "stops", "pagesdocuments", "events", "news"]
        .map(index => this._renderIndex(results, index))
        .join("");
    }
  }

  renderResult(index) {
    return (hit) => {
      return `
        <div class="c-search-result__hit">
          ${AlgoliaResult.renderResult(hit, index)}
        </div>
      `;
    }
  }
}

AlgoliaResults.indexTitles = {
  stops: "Stations and Stops",
  routes: "Lines and Routes",
  pagesdocuments: "Pages and Documents",
  events: "Events",
  news: "News"
}

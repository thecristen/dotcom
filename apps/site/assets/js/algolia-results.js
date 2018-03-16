import hogan from 'hogan.js';

const TEMPLATES = {
  contentResults: hogan.compile(`
    <div class="c-search-results__section">
      {{#hasHits}}
        <div class="c-search-result__header">{{title}}</div>
        {{#hits}}
          <div class="c-search-result__hit">
            <a class="hit-content" onclick="Turbolinks.visit('{{hitUrl}}')">
              <span>{{{hitIcon}}}</span>
              <span class="hit-name">{{hitTitle}}</span>
            </a>
          </div>
        {{/hits}}
        {{#nbHits}}
          <div class="c-search-result__footer">{{nbHits}} results</div>
        {{/nbHits}}
      {{/hasHits}}
    </div>
 `),
  fontAwesomeIcon: hogan.compile(`
    <span aria-hidden="true" class="c-search-result__content-icon fa {{icon}}"></span>
 `)
};

export class AlgoliaResults {
  _getFeatureIcon(feature) {
    const icon = document.getElementById(`icon-feature-${feature}`);
    if (icon) {
      return icon.innerHTML;
    } else {
      return "";
    }
  }

  _fileIcon(hit) {
    switch (hit._file_type) {
      case "application/pdf":
        return "fa-file-pdf-o";

      case "application/vnd.openxmlformats-officedocument.presentationml.presentation":
        return "fa-file-powerpoint-o";

      case "application/vnd.ms-excel":
        return "fa-file-excel-o";

      default:
        return "fa-file-o";
    }
  }

  _contentIcon(hit) {
    let icon;

    if (hit.search_api_datasource === "entity:file") {
      icon = this._fileIcon(hit);
    } else {
      const iconMapper = {
        search_result: "fa-search",
        news_entry: "fa-newspaper-o",
        event: "fa-calendar",
        page: "fa-file-o",
        landing_page: "fa-file-o",
        person: "fa-user"
      };
      icon = iconMapper[hit._content_type] || "fa-file-o";
    }

    return TEMPLATES.fontAwesomeIcon.render({icon: icon});
  }

  _contentTitle(hit) {
    if (hit.search_api_datasource === "entity:file") {
      return hit.file_name_raw;
    } else if (hit.type == "search_result") {
      return hit.search_result_title;
    } else {
      return hit.content_title;
    }
  }

  _contentUrl(hit) {
    if (hit.search_api_datasource === "entity:file") {
      return  "/sites/default/files/" + hit._file_uri.replace(/public:\/\//, "");
    } else if (hit.type == "search_result") {
      return hit._search_result_url;
    } else {
      return hit._content_url;
    }
  }

  _subwayRouteIcon(routeId) {
    const mapper = {
      Red: "red_line",
      Orange: "orange_line",
      Blue: "blue_line",
      Mattapan: "mattapan_trolley"
    };

    return mapper[routeId] || "green_line";
  }

  _iconFromRoute(route) {
    switch (route.type) {
      case 2:
        return "commuter_rail";

      case 3:
        return "bus";

      case 4:
        return "ferry";

      default:
        return this._subwayRouteIcon(route.id);
      }
  }

  _hitsFilter(hits, type) {
    const mappedHits =  hits.map((hit) => {
      return Object.assign(hit, {hitIcon: this._getHitIcon(hit, type),
                                 hitUrl: this._getHitUrl(hit, type),
                                 hitTitle: this._getHitTitle(hit, type)
      });
    });

    return mappedHits;
  }

  _renderIndex(results, index, title) {
    let renderedHTML = "";

    if (results[index]) {
      const hits = this._hitsFilter(results[index].hits, index);

      const content = { title: title,
                        nbHits: results[index].nbHits,
                        hits: hits,
                        hasHits: results[index].nbHits > 0,
      };
      renderedHTML = TEMPLATES.contentResults.render(content);
    }
    return renderedHTML;
  }

  _getHitIcon(hit, type) {
    switch(type) {
      case "stops":
        return this._getFeatureIcon("stop");

      case "routes":
        const iconName = this._iconFromRoute(hit.route);
        return this._getFeatureIcon(iconName);

      case "drupal":
        return this._contentIcon(hit);

      default:
        console.error(`Invalid index type: ${type}`);
        return ""
    }
  }

  _getHitUrl(hit, type) {
    switch(type) {
      case "stops":
        return `/stops/${hit.stop.id}`;

      case "routes":
        return `/schedules/${hit.route.id}/line`;

      case "drupal":
        return this._contentUrl(hit);

      default:
        console.error(`Invalid index type: ${type}`);
        return "#"
    }
  }

  _getHitTitle(hit, type) {
    switch(type){
      case "stops":
        return hit.stop.name;

      case "routes":
        return hit.route.name;

      case "drupal":
        return this._contentTitle(hit);

      default:
        console.error(`Invalid index type: ${type}`);
        return ""
    }
  }

  init() {
  }

  render(results)  {
    const routesHTML = this._renderIndex(results, "routes", "Lines and Routes");
    const stopsHTML = this._renderIndex(results, "stops", "Stations and Stops");
    const contentHTML = this._renderIndex(results, "drupal", "Events, News, Pages and Documents");

    const container = document.getElementById('search-results');
    if (container) {
      container.innerHTML = routesHTML + stopsHTML + contentHTML;
    }
  }
}

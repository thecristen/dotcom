import hogan from "hogan.js";

export const TEMPLATES = {
  fontAwesomeIcon: hogan.compile(`<span aria-hidden="true" class="c-search-result__content-icon fa {{icon}}"></span>`),
  formattedDate: hogan.compile(`<span class="c-search-result__event-date">{{date}}</span>`),
  locations: hogan.compile(`
    <a id="hit-{{id}}" class="c-search-result__link" url={{hitUrl}}>
      <span>{{{hitIcon}}}</span>
      <span class="c-search-result__hit-name">{{{hitTitle}}}</span>
    </a>
  `),
  usemylocation: hogan.compile(`
    <span id="search-bar__my-location" class="c-search-bar__my-location">
      <i aria-hidden="true" class="fa fa-location-arrow "></i>
      Use my location
      <i aria-hidden="true" id="search-result__loading-indicator" class="fa fa-cog fa-spin c-search-result__loading-indicator"></i>
    </span>
  `),
  default: hogan.compile(`
    {{#id}}
    <a id="hit-{{id}}" class="c-search_result__link" href="{{hitUrl}}">
    {{/id}}
    {{^id}}
    <a class="c-search_result__link" href="{{hitUrl}}">
    {{/id}}
      <span>{{{hitIcon}}}</span>
      <span class="c-search-result__hit-name">{{{hitTitle}}}</span>
    </a>
    <span class="c-search-result__feature-icons">
      {{#hitFeatureIcons}}
        {{{.}}}
      {{/hitFeatureIcons}}
    </span>
  `)
};

export function renderResult(hit, type) {
  if (TEMPLATES[type]) {
    return TEMPLATES[type].render(parseResult(hit, type));
  }
  return TEMPLATES.default.render(parseResult(hit, type));
}

export function parseResult(hit, type) {
  return Object.assign(hit, {
    hitIcon: getIcon(hit, type),
    hitUrl: getUrl(hit, type),
    hitTitle: getTitle(hit, type),
    hitFeatureIcons: getFeatureIcons(hit, type),
    id: hit.place_id || null
  });
}

export function getIcon(hit, type) {
  switch(type) {
    case "locations":
      hit._content_type = "locations";
      return _contentIcon(hit);
    case "stops":
      return _getStopOrStationIcon(hit);

    case "routes":
      const iconName = _iconFromRoute(hit.route);
      return featureIcon(iconName);

    case "drupal":
    case "pagesdocuments":
    case "events":
    case "news":
      return _contentIcon(hit);

    case "usemylocation":
      return "";

    default:
      console.error(`AlgoliaResult.getIcon not implemented for index: ${type}`);
      return ""
  }
};

export function featureIcon(feature) {
  const icon = document.getElementById(`icon-feature-${feature}`);
  if (icon) {
    return icon.innerHTML;
  } else {
    return "";
  }
};

function _fileIcon(hit) {
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
};

function _contentIcon(hit) {
  let icon;

  if (hit.search_api_datasource === "entity:file") {
    icon = _fileIcon(hit);
  } else {
    const iconMapper = {
      search_result: "fa-search",
      news_entry: "fa-newspaper-o",
      event: "fa-calendar",
      page: "fa-file-o",
      landing_page: "fa-file-o",
      person: "fa-user",
      locations: "fa-map-marker"
    };
    icon = iconMapper[hit._content_type] || "fa-file-o";
  }

  return TEMPLATES.fontAwesomeIcon.render({icon: icon});
};

function _subwayRouteIcon (routeId) {
  const mapper = {
    Red: "red_line",
    Orange: "orange_line",
    Blue: "blue_line",
    Mattapan: "mattapan_trolley"
  };

  return mapper[routeId] || "green_line";
};

function _iconFromRoute(route) {
  switch (route.type) {
    case 2:
      return "commuter_rail";

    case 3:
      return "bus";

    case 4:
      return "ferry";

    default:
      return _subwayRouteIcon(route.id);
    }
};

export function getTitle(hit, type) {
  switch(type){
    case "locations":
      return hit.description;
    case "stops":
      return hit._highlightResult.stop.name.value;

    case "routes":
      return hit._highlightResult.route.name.value;

    case "drupal":
    case "pagesdocuments":
    case "events":
    case "news":
      return _contentTitle(hit);

    case "usemylocation":
      return "";

    default:
      console.error(`AlgoliaResult.getTitle not implemented for index: ${type}`);
      return ""
  }
};

function _contentTitle(hit) {
  if (hit.search_api_datasource === "entity:file") {
    return hit._highlightResult.file_name_raw.value;
  } else {
    return hit._highlightResult.content_title.value;
  }
};

export function getUrl(hit, type) {
  switch(type) {
    case "stops":
      return `/stops/${hit.stop.id}`;

    case "routes":
      return `/schedules/${hit.route.id}/line`;

    case "drupal":
    case "pagesdocuments":
    case "events":
    case "news":
      return _contentUrl(hit);

    case "locations":
      return "";
    case "usemylocation":
      return "#";

    default:
      console.error(`AlgoliaResult.getUrl not implemented for index: ${type}`);
      return "#"
  }
};

function _contentUrl(hit) {
  if (hit.search_api_datasource === "entity:file") {
    return  "/sites/default/files/" + hit._file_uri.replace(/public:\/\//, "");
  } else if (hit._content_type == "search_result") {
    return hit._search_result_url.replace(/internal:/, "");
  } else {
    return hit._content_url;
  }
};

function _getCommuterRailZone(hit) {
   if (hit.zone) {
     return [`<span class="c-search-results__commuter-rail-zone">Zone ${hit.zone}</span>`];
   } else {
     return [];
   }
 }

function _stopsWithAlerts() {
  const stopsWithAlertsDiv = document.getElementById("stops-with-alerts");
  let stopsWithAlerts = "";
  if (stopsWithAlertsDiv) {
    stopsWithAlerts = stopsWithAlertsDiv.dataset.stopsWithAlerts;
  }
  return stopsWithAlerts
}

function _routesWithAlerts() {
  const routesWithAlertsDiv = document.getElementById("routes-with-alerts");
  let routesWithAlerts = "";
  if (routesWithAlertsDiv) {
    routesWithAlerts = routesWithAlertsDiv.dataset.routesWithAlerts;
  }

  return routesWithAlerts;
}

function _getAlertIcon(hit, type) {
   let hasAlert = false;
   switch(type) {
     case "stops":
       hasAlert = _stopsWithAlerts().includes(hit.stop.id);
       break;

     case "routes":
       hasAlert = _routesWithAlerts().includes(hit.route.id);
       break;
   }

   return hasAlert ? ["alert"] : [];
 }

function _featuresToIcons(features) {
   return features.map((feature) => {
     const icon = document.getElementById(`icon-feature-${feature}`);
     if (icon) {
       return icon.innerHTML;
     } else {
       console.error(`Can't find feature: ${feature}`);
       return "";
     }
   });
 }

function _sortFeatures(features) {
   const featuresWithoutBranches = features.filter((feature) => !feature.includes("Green-"));
   const branches = features.filter((feature) => feature.includes("Green-"));
   if (branches.length > 0) {
     const greenLinePosition = featuresWithoutBranches.findIndex((feature) => feature === "green_line");

     featuresWithoutBranches.splice(greenLinePosition + 1, 0, ...branches);
     return featuresWithoutBranches;

   } else {
     return features;
   }
 }

export function getFeatureIcons(hit, type) {
  const alertFeature = _getAlertIcon(hit, type);
  switch(type) {
    case "stops":
      return _stopIcons(hit, type);

    case "routes":
      return _featuresToIcons(alertFeature)

    case "events":
    case "news":
      return _contentDate(hit);

    default:
      return [];
  }
}

function _stopIcons(hit, type) {
  const filteredFeatures = hit.features.filter((feature) => ((feature != "access") && (feature != "parking_lot")));

  const alertFeature = _getAlertIcon(hit, type);
  const branchFeatures = hit.green_line_branches || [];
  const allFeatures = alertFeature
                        .concat(branchFeatures)
                        .concat(filteredFeatures);
  const allFeaturesSorted = _sortFeatures(allFeatures);
  const allIcons = _featuresToIcons(allFeaturesSorted);

  const zoneIcon = _getCommuterRailZone(hit);

  return allIcons.concat(zoneIcon);
}

function _contentDate(hit) {
  const dateString = hit._content_url.split("/")[2]
  try {
    const dateStringWithTime = `${dateString}T01:00:00`;
    const date = new Date(dateStringWithTime);
    return [_formatDate(date)];
  }
  catch(err) {
    console.error(`Invalid date detected in AlgoliaResult.getFeatureIcons (${dateString})`);
    return []
  }
}

function _formatDate(date) {
  const formattedDate = date.toLocaleDateString("en-US", {year: 'numeric', month: 'short', day: 'numeric'});
  return TEMPLATES.formattedDate.render({date: formattedDate});
}

function _getStopOrStationIcon(hit) {
  if (hit.stop["station?"]) {
    return featureIcon("station");
  } else {
    return featureIcon("stop");
  }
}


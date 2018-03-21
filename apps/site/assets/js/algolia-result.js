import hogan from "hogan.js";

export const TEMPLATES = {
  fontAwesomeIcon: hogan.compile(`<span aria-hidden="true" class="c-search-result__content-icon fa {{icon}}"></span>`),
  default: hogan.compile(`
    <div class="c-search-result__hit">
      <a class="hit-content" onclick="Turbolinks.visit('{{hitUrl}}')">
        <span>{{{hitIcon}}}</span>
        <span class="hit-name">{{hitTitle}}</span>
      </a>
    </div>
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
    hitTitle: getTitle(hit, type)
  });
}

export function getIcon(hit, type) {
  switch(type) {
    case "stops":
      return _featureIcon("stop");

    case "routes":
      const iconName = _iconFromRoute(hit.route);
      return _featureIcon(iconName);

    case "drupal":
    case "pagesdocuments":
    case "events":
    case "news":
      return _contentIcon(hit);

    default:
      console.error(`AlgoliaResult.getIcon not implemented for index type: ${type}`);
      return ""
  }
};

function _featureIcon(feature) {
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
      person: "fa-user"
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
    case "stops":
      return hit.stop.name;

    case "routes":
      return hit.route.name;

    case "drupal":
    case "pagesdocuments":
    case "events":
    case "news":
      return _contentTitle(hit);

    default:
      console.error(`Invalid index type: ${type}`);
      return ""
  }
};

function _contentTitle(hit) {
  if (hit.search_api_datasource === "entity:file") {
    return hit.file_name_raw;
  } else {
    return hit.content_title;
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

    default:
      console.error(`AlgoliaResult.getUrl not implemented for index type: ${type}`);
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

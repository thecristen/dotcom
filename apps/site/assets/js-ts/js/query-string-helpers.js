export function parseQuery(query) {
  const params = {};
  if (!query) return params;
  const queryParams = query.substring(1).split("&");
  queryParams.forEach(param => {
    const split = param.split("=");
    params[window.decodeURIComponent(split[0])] = window.decodeURIComponent(
      split[1].replace(/\+/g, " ")
    );
  });
  return params;
}

export function parseParams(params) {
  if (!params || Object.keys(params).length === 0) {
    return "";
  }

  return `?${Object.keys(params)
    .map(key => `${key}=${window.encodeURIComponent(params[key])}`)
    .join("&")}`;
}

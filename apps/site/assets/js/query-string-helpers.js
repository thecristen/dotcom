export function parseQuery(query) {
  const params = {};
  if (!query) return params;
  const queryParams = query.substring(1).split("&");
  queryParams.forEach(param => {
    const split = param.split("=");
    params[split[0]] = split[1].replace(/\+/g, " ");
  });
  return params;
}

export function parseParams(params) {
  params = params || {};
  if (Object.keys(params).length == 0) {
    return "";
  }

  return "?" + Object.keys(params)
                     .map(key => `${key}=${params[key].replace(/\s/g, "+")}`)
                     .join("&");
}

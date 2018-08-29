const showLoadingIndicators = (bool) => {
  const method = bool ? "remove" : "add";
  const loadingIndicators = document.getElementsByClassName("js-loc-loading-indicator");
  return Array.from(loadingIndicators).forEach(icon => icon.classList[method]("hidden-xs-up"));
}

export const onLocation = loc => {
  showLoadingIndicators(false);
  const { latitude, longitude } = loc.coords;
  const qs = `?latitude=${latitude}&longitude=${longitude}`;
  return window.Turbolinks.visit(encodeURI(window.location.protocol + qs));
};

export const onError = error => {
  showLoadingIndicators(false);

  if (error.message && error.message.includes("denied")) {
    return false;
  }

  const msgEl = document.getElementById("address-search-message");
  if (msgEl) {
    msgEl.innerHTML = `There was an error retrieving your current location;
                       please enter an address to see transit near you.`;
  }
};

export const onLoad = ({ data }) => {
  if (data && data.url) {
    const url = window.decodeURIComponent(data.url);

    if (
      window.navigator &&
      window.navigator.geolocation &&
      url.includes("/transit-near-me") &&
      url.includes("address") === false &&
      url.includes("latitude") === false &&
      url.includes("longitude") === false
    ) {
      showLoadingIndicators(true);
      window.navigator.geolocation.getCurrentPosition(onLocation, onError);
    }
  }
  return true;
};

export default () => {
  document.addEventListener("turbolinks:load", onLoad);
  return true;
};

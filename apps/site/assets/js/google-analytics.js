const track = () => {
  window.dataLayer.push({
    event: "pageView"
  });
};

export default () => {
  document.addEventListener("turbolinks:load", track);
};

export {};
declare global {
  interface Window {
    /* eslint-disable typescript/no-explicit-any */
    Turbolinks: any;
    decodeURIComponent: any;
    autocomplete: any;
    jQuery: any;
    /* eslint-enable typescript/no-explicit-any */
  }
}
window.jQuery = require("jquery");
window.autocomplete = require("autocomplete.js");
window.Turbolinks = require("turbolinks");

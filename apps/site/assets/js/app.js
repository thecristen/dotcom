// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "assets/js/socket".

window.$ = window.jQuery;

// Polyfills
window.nextTick = function nextTick(f) {  window.setTimeout(f, 0); };

window.requestAnimationFrame = window.requestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  function(f) { window.setTimeout(f, 15); };

// Source: https://github.com/Alhadis/Snippets/blob/master/js/polyfills/IE8-child-elements.js
if (!("previousElementSibling" in document.documentElement)) {
  Object.defineProperty(Element.prototype, "previousElementSibling", {
    get: function() {
      var e = this.previousSibling;
      while (e && 1 !== e.nodeType) {
         e = e.previousSibling;
      }
      return e;
    }
  });
}

if (!("nextElementSibling" in document.documentElement)) {
  Object.defineProperty(Element.prototype, "nextElementSibling", {
    get: function() {
      var e = this.nextSibling;
      while (e && 1 !== e.nodeType) {
        e = e.nextSibling;
      }
      return e;
    }
  });
}

// Production steps of ECMA-262, Edition 5, 15.4.4.19
// Reference: http://es5.github.io/#x15.4.4.19
if (!Array.prototype.map) {
  Array.prototype.map = function(callback/*, thisArg*/) {
    var T, A, k;
    if (this == null) {
      throw new TypeError('this is null or not defined');
    }
    var O = Object(this);
    var len = O.length >>> 0;
    if (typeof callback !== 'function') {
      throw new TypeError(callback + ' is not a function');
    }
    if (arguments.length > 1) {
      T = arguments[1];
    }
    A = new Array(len);
    // 7. Let k be 0
    while (k < len) {

      var kValue, mappedValue;
      if (k in O) {
        kValue = O[k];
        mappedValue = callback.call(T, kValue, k, O);
        A[k] = mappedValue;
      }
      k++;
    }
    return A;
  };
}

 // Production steps of ECMA-262, Edition 6, 22.1.2.1
 // Reference: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/from
if (!Array.from) {
  Array.from = (function () {
    var toStr = Object.prototype.toString;
    var isCallable = function (fn) {
      return typeof fn === 'function' || toStr.call(fn) === '[object Function]';
    };
    var toInteger = function (value) {
      var number = Number(value);
      if (isNaN(number)) { return 0; }
      if (number === 0 || !isFinite(number)) { return number; }
      return (number > 0 ? 1 : -1) * Math.floor(Math.abs(number));
    };
    var maxSafeInteger = Math.pow(2, 53) - 1;
    var toLength = function (value) {
      var len = toInteger(value);
      return Math.min(Math.max(len, 0), maxSafeInteger);
    };

    // The length property of the from method is 1.
    return function from(arrayLike/*, mapFn, thisArg */) {
      // 1. Let C be the this value.
      var C = this;

      // 2. Let items be ToObject(arrayLike).
      var items = Object(arrayLike);

      // 3. ReturnIfAbrupt(items).
      if (arrayLike == null) {
        throw new TypeError('Array.from requires an array-like object - not null or undefined');
      }

      // 4. If mapfn is undefined, then let mapping be false.
      var mapFn = arguments.length > 1 ? arguments[1] : void undefined;
      var T;
      if (typeof mapFn !== 'undefined') {
        // 5. else
        // 5. a If IsCallable(mapfn) is false, throw a TypeError exception.
        if (!isCallable(mapFn)) {
          throw new TypeError('Array.from: when provided, the second argument must be a function');
        }

        // 5. b. If thisArg was supplied, let T be thisArg; else let T be undefined.
        if (arguments.length > 2) {
          T = arguments[2];
        }
      }

      // 10. Let lenValue be Get(items, "length").
      // 11. Let len be ToLength(lenValue).
      var len = toLength(items.length);

      // 13. If IsConstructor(C) is true, then
      // 13. a. Let A be the result of calling the [[Construct]] internal method
      // of C with an argument list containing the single item len.
      // 14. a. Else, Let A be ArrayCreate(len).
      var A = isCallable(C) ? Object(new C(len)) : new Array(len);

      // 16. Let k be 0.
      var k = 0;
      // 17. Repeat, while k < len… (also steps a - h)
      var kValue;
      while (k < len) {
        kValue = items[k];
        if (mapFn) {
          A[k] = typeof T === 'undefined' ? mapFn(kValue, k) : mapFn.call(T, kValue, k);
        } else {
          A[k] = kValue;
        }
        k += 1;
      }
      // 18. Let putStatus be Put(A, "length", len, true).
      A.length = len;
      // 20. Return A.
      return A;
    };
  }());
}

// https://tc39.github.io/ecma262/#sec-array.prototype.find
// Reference: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/find
if (!Array.prototype.find) {
  Object.defineProperty(Array.prototype, 'find', {
    value: function(predicate) {
      // 1. Let O be ? ToObject(this value).
      if (this == null) {
        throw new TypeError('"this" is null or not defined');
      }

      var o = Object(this);

      // 2. Let len be ? ToLength(? Get(O, "length")).
      var len = o.length >>> 0;

      // 3. If IsCallable(predicate) is false, throw a TypeError exception.
      if (typeof predicate !== 'function') {
        throw new TypeError('predicate must be a function');
      }

      // 4. If thisArg was supplied, let T be thisArg; else let T be undefined.
      var thisArg = arguments[1];

      // 5. Let k be 0.
      var k = 0;

      // 6. Repeat, while k < len
      while (k < len) {
        // a. Let Pk be ! ToString(k).
        // b. Let kValue be ? Get(O, Pk).
        // c. Let testResult be ToBoolean(? Call(predicate, T, « kValue, k, O »)).
        // d. If testResult is true, return kValue.
        var kValue = o[k];
        if (predicate.call(thisArg, kValue, k, o)) {
          return kValue;
        }
        // e. Increase k by 1.
        k++;
      }

      // 7. Return undefined.
      return undefined;
    }
  });
}

// breakpoints defined in assets/css/_variables.scss
const breakpoints = {xs: 0, sm: 544, md: 800, lg: 1088, xxl: 1344};

// Imports
import "babel-polyfill";
import googleMapsLoaded from './google-maps-loaded';
import submitOnEvents from './submit-on-events';
import selectModal from './select-modal';
import collapse from './collapse';
import headerDropdowns from './header-dropdowns';
import modal from './modal';
import turbolinks from './turbolinks';
import supportForm from './support-form';
import objectFitImages from 'object-fit-images';
import fixedsticky from './fixedsticky';
import horizsticky from './horizsticky';
import menuCtrlClick from './menu-ctrl-click';
import carousel from './carousel';
import geoLocation from './geolocation';
import addressSearch from './address-search';
import autocomplete from './autocomplete';
import googleMap from './google-map';
import scrollTo from './scroll-to';
import stickyTooltip from './sticky-tooltip';
import timetableScroll from './timetable-scroll';
import menuClose from './menu-close';
import datePicker from './date-picker';
import toggleBtn from './toggle-on-click';
import tripPlan from './trip-plan';
import stopBubbles from './stop-bubbles';
import search from './search';
import photoGallery from './photo-gallery';
import filter from './filter';
import * as stopsSearch from "./algolia-stop-search";
import * as homepageSearch from "./algolia-homepage-search";
import * as globalSearch from "./algolia-global-search";
import AlgoliaResults from "./algolia-results";
import fullstory from './fullstory';
import inputFocus from './input-focus';

submitOnEvents(["blur", "change"]);
googleMapsLoaded();
selectModal();
headerDropdowns();
collapse();
modal();
turbolinks();
supportForm();
fixedsticky();
horizsticky();
objectFitImages(); // Polyfill for IE object-fit support
menuCtrlClick();
carousel();
inputFocus();
geoLocation();
addressSearch();
autocomplete();
googleMap();
scrollTo();
timetableScroll();
menuClose();
datePicker();
toggleBtn();
tripPlan();
stopBubbles();
search(window.$, breakpoints);
photoGallery();
filter();
stickyTooltip();
globalSearch.init();
homepageSearch.init();
stopsSearch.init();
fullstory();

document.body.className = document.body.className.replace("no-js", "js");

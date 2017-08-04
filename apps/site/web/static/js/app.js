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
// paths "./socket" or full ones "web/static/js/socket".

window.$ = window.jQuery;

// Polyfills
window.nextTick = function nextTick(f) {  window.setTimeout(f, 0); };

window.requestAnimationFrame = window.requestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  function(f) { window.setTimeout(f, 15); };


// Source: https://github.com/Alhadis/Snippets/blob/master/js/polyfills/IE8-child-elements.js
if(!("previousElementSibling" in document.documentElement)){
    Object.defineProperty(Element.prototype, "previousElementSibling", {
        get: function(){
            var e = this.previousSibling;
            while(e && 1 !== e.nodeType)
                e = e.previousSibling;
            return e;
        }
    });
}

if(!("nextElementSibling" in document.documentElement)){
    Object.defineProperty(Element.prototype, "nextElementSibling", {
        get: function(){
            var e = this.previousSibling;
            while(e && 1 !== e.nodeType)
                e = e.previousSibling;
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

// Imports
import submitOnEvents from './submit-on-events';
import selectModal from './select-modal';
import tooltip from './tooltip';
import collapse from './collapse';
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

submitOnEvents(["blur", "change"]);
selectModal();
tooltip();
collapse();
modal();
turbolinks();
supportForm();
fixedsticky();
horizsticky();
objectFitImages(); // Polyfill for IE object-fit support
menuCtrlClick();
carousel();
geoLocation();
addressSearch();
autocomplete();
googleMap();
scrollTo();
stickyTooltip();
timetableScroll();
menuClose();
datePicker();
toggleBtn();
tripPlan();
stopBubbles();
search();

document.body.className = document.body.className.replace("no-js", "js");

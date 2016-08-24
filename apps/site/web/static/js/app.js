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

// import socket from "./socket"
import submitOnEvents from './submit-on-events.js';
import dateToggle from './date-toggle.js';
import imageExpand from './image-expand.js';
import dismissAnnouncement from './dismiss-announcement.js';
import selectModal from './select-modal.js';
import tooltip from './tooltip.js';
import turbolinks from './turbolinks';
import supportForm from './support-form.js';

submitOnEvents(["blur", "change"]);
dateToggle();
imageExpand();
dismissAnnouncement();
selectModal();
tooltip();
turbolinks();
supportForm();

$("body").removeClass("no-js").addClass("js");

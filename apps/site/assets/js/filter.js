export default function($) {
  $ = $ || window.jQuery;
  document.addEventListener('turbolinks:load', setupInput, {passive: true});
}

function setupInput(){
  var $input = $("[data-filter-input]");

  if ($input.length != 0) {
    $input.keyup(() => keyUp($input)); // set keypUp function
    keyUp($input) // Run function on existing input
  }
  hideErrorContainer();
}

function keyUp($input) {
  const $modeButtons = $("[data-link-filter]");
  $modeButtons.each(function(i, el) {filter_element($input.val(), el)});

  if (visibleModeButtons().length) {
    hideEmptyMessage();
  } else {
    displayEmptyMessage($input.val());
  }
  disableButton($input.val());
}

function filter_element(val, element) {
  var $el = $(element);

  if ($el.text().toLowerCase().indexOf(val.toLowerCase()) > -1) {
    $el.show();
  } else {
    $el.hide();
  }
  $("#filter-error-container").hide();
}

function displayEmptyMessage(val) {
  $("[data-filter-empty]").html(`<p>There are no bus routes matching "${val}".</p>`);
  $("[data-filter-empty]").show();
}

function hideEmptyMessage() {
  $("[data-filter-empty]").hide();
}

function disableButton(input) {
  const $button = $("[data-filter-submit]");
  const buttonClass = "filter-btn-disabled"

  if (input == "") {
    $button.attr("disabled", true);
    $button.addClass(buttonClass);
  } else {
    $button.attr("disabled", false);
    $button.removeClass(buttonClass);
  }
}

function hideErrorContainer() {
  if (visibleModeButtons().length) {
    $("#filter-error-container").show()
  } else {
    $("#filter-error-container").hide()
  }
}

function visibleModeButtons() {
  return $("[data-link-filter]").children(':visible');
}

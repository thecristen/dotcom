export default function errorBus($) {
  $ = $ || window.jQuery;

  setInterval(function() {
    $("#error-bus").attr('src', '/images/error-bus-join-us.gif');
  }, 5000);
}

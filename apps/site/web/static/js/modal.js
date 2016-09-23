export default function($) {
  $ = $ || window.jQuery;

  function closeModals() {
    $('.modal.in').modal('hide');
  };

  $(document).on('turbolinks:before-cache', closeModals);
};

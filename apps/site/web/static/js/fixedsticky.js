export default function() {
  function fixedsticky() {
    $(".fixedsticky").fixedsticky('destroy');
    $(".fixedsticky").fixedsticky();
  }
  $(document).on('turbolinks:load', fixedsticky);
  $(document).on('shown.bs.collapse', fixedsticky);
}

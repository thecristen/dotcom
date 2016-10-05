export default function() {
  function fixedsticky() {
    $(".fixedsticky").fixedsticky();
  }
  $(document).on('turbolinks:load', fixedsticky);
  fixedsticky();
}

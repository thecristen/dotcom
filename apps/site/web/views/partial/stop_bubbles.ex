defmodule Site.PartialView.StopBubbles do
  use Site.Web, :view

  alias Site.StopBubble.Params

  @spec render_stop_bubbles([Params.t]) :: Phoenix.HTML.safe
  def render_stop_bubbles(params) do
    content_tag :div, class: "route-branch-stop-bubbles" do
      for param <- params do
        Site.PartialView.render("_stop_bubble_container.html", Map.from_struct(param))
      end
    end
  end
end

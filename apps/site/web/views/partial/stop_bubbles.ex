defmodule Site.PartialView.StopBubbles do
  use Site.Web, :view

  alias Site.StopBubble.Params

  @spec render_stop_bubbles([Params.t]) :: Phoenix.HTML.safe
  def render_stop_bubbles(params, add_expand_icon? \\ false, stop_branch \\ nil) do
    content_tag :div, class: "route-branch-stop-bubbles" do
      for param <- params do
        add_branch_expand_icon = add_expand_icon? && (is_nil(stop_branch) || param.bubble_branch == stop_branch)
        param = param
                |> Map.from_struct()
                |> Map.put(:add_expand_icon?, add_branch_expand_icon)
        Site.PartialView.render("_stop_bubble_container.html", param)
      end
    end
  end
end

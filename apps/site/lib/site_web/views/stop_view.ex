defmodule SiteWeb.StopView do
  @moduledoc """
  View helpers for the Stop controller
  """
  use SiteWeb, :view

  alias Phoenix.HTML
  alias Site.React

  @spec render_react(map) :: HTML.safe()
  def render_react(assigns) do
    Util.log_duration(__MODULE__, :do_render_react, [assigns])
  end

  @spec do_render_react(map) :: HTML.safe()
  def do_render_react(%{stop_page_data: stop_page_data, map_data: map_data, map_id: map_id}) do
    React.render(
      "StopPage",
      %{
        stopPageData: stop_page_data,
        mapData: map_data,
        mapId: map_id
      }
    )
  end
end

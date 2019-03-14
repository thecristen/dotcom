defmodule SiteWeb.StopView do
  use SiteWeb, :view

  alias Phoenix.HTML
  alias Site.React
  alias Stops.Stop

  @spec render_react(map) :: HTML.safe()
  def render_react(assigns) do
    Util.log_duration(__MODULE__, :do_render_react, [assigns])
  end

  @spec do_render_react(map) :: HTML.safe()
  def do_render_react(%{stop: %Stop{} = stop, map_data: map_data}) do
    React.render(
      "StopPage",
      %{
        stopPageData: %{stop: stop},
        mapData: map_data,
        mapId: "map"
      }
    )
  end
end

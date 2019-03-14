defmodule SiteWeb.StopViewTest do
  use ExUnit.Case, async: false

  alias SiteWeb.StopView
  alias Stops.Repo

  test "render_react returns HTML" do
    south_station = Repo.get("place-sstat")

    assert {:safe, "<div" <> _} =
             StopView.render_react(%{
               stop: south_station,
               map_data: %{}
             })
  end
end

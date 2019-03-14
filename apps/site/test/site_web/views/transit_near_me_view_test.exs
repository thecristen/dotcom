defmodule SiteWeb.TransitNearMeViewTest do
  use ExUnit.Case
  alias SiteWeb.TransitNearMeView

  test "render_react returns HTML" do
    assert {:safe, "<div class=\"m-tnm\"" <> _} =
             TransitNearMeView.render_react(%{
               routes_json: [],
               stops_json: [],
               map_data: %{}
             })
  end
end

defmodule Site.FareController.OriginDestinationTest do
  use Site.ConnCase, async: true

  alias Site.FareController.OriginDestinationFareBehavior, as: ODFB

  describe "before_render/2" do
    test "assigns relevant information", %{conn: conn} do
      module = Site.FareController.Ferry
      conn = ODFB.before_render(conn, module)
      for key <- ~w(mode route_type origin_stops destination_stops key_stops origin destination)a do
        assert Map.has_key?(conn.assigns, key)
      end
    end
  end
end

defmodule Site.StationViewTest do
  @moduledoc false
  alias Site.StationView
  use Site.ConnCase, async: true

  describe "type_mode/1" do
    test "return correct type mode for all modes" do
      assert StationView.type_mode(:bus) == "bus_subway"
      assert StationView.type_mode(:subway) == "bus_subway"
      assert StationView.type_mode(:commuter) == "commuter"
      assert StationView.type_mode(:ferry) == "ferry"
    end
  end
end

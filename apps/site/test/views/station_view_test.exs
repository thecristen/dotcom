defmodule Site.StationViewTest do
  @moduledoc false
  alias Site.StationView
  use Site.ConnCase, async: true

  describe "fare_group/1" do
    test "return correct fare group for all modes" do
      assert StationView.fare_group(:bus) == "bus_subway"
      assert StationView.fare_group(:subway) == "bus_subway"
      assert StationView.fare_group(:commuter) == "commuter"
      assert StationView.fare_group(:ferry) == "ferry"
    end
  end
end

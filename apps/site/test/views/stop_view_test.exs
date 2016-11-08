defmodule Site.StopViewTest do
  @moduledoc false
  alias Site.StopView
  use Site.ConnCase, async: true

  describe "fare_group/1" do
    test "return correct fare group for all modes" do
      assert StopView.fare_group(:bus) == "bus_subway"
      assert StopView.fare_group(:subway) == "bus_subway"
      assert StopView.fare_group(:commuter) == "commuter"
      assert StopView.fare_group(:ferry) == "ferry"
    end
  end
end

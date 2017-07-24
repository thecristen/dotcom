defmodule Fares.RetailLocationsDataTest do
  use ExUnit.Case, async: true
  alias Fares.RetailLocations.{Location, Data}

  describe "Fares.RetailLocationsData" do
    test "get/1 retrieves an array of retail locations data" do
      data = Data.get
      assert is_list data
      refute data == []
    end

    test "all locations have latitude & longitude values" do
      for %Location{latitude: lat, longitude: lng} <- Data.get do
        assert lat > 41
        assert lat < 43
        assert is_float(lat) == true
        assert lng < -70
        assert lng > -72
        assert is_float(lng) == true
      end
    end

    test "build_r_tree returns a tree with all location data" do
      tree = Data.build_r_tree()
      for %Location{name: name} = location <- Data.get do
        assert [%Location{name: ^name}] = Data.k_nearest_neighbors(tree, location, 1)
      end
    end
  end
end

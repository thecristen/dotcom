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
  end
end

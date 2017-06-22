defmodule Site.StopController.StopMapTest do
  use ExUnit.Case
  import Site.StopController.StopMap
  alias Stops.Stop

  describe "map_info/1" do
    @stop %Stop{
      latitude: 42.5,
      longitude: -71.8,
      station?: false
    }

    test "map has correct dimensions and locations" do
      {map_data, _srcset, _static_url} = map_info(@stop)
      marker = List.first(map_data.markers)

      assert map_data.width == 735
      assert map_data.height == 250
      assert marker.latitude == 42.5
      assert marker.longitude == -71.8
    end

    test "srcset contains all sizes for both scales" do
      {_map_data, srcset, _static_url} = map_info(@stop)
      sizes = [140, 280, 340, 400, 520]
      doubled_sizes = Enum.map(sizes, & &1 * 2)
      for {size, doubled_size} <- Enum.zip(sizes, doubled_sizes) do
        assert srcset =~ "#{size}w"
        assert srcset =~ "#{doubled_size}w"
      end
    end

    test "returns google maps url" do
      {_map_data, _srcset, static_url} = map_info(@stop)
      assert static_url =~ "https://maps.googleapis.com/maps/api/staticmap"
      assert static_url =~ Float.to_string(@stop.latitude)
      assert static_url =~ Float.to_string(@stop.longitude)
    end
  end
end

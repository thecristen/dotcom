defmodule GoogleMaps.MapDataTest do
  use ExUnit.Case
  import GoogleMaps.MapData
  alias GoogleMaps.MapData
  alias GoogleMaps.MapData.{Marker, Path}

  @markers [
    %Marker {
      latitude: "42.355041",
      longitude: "-71.066065",
      icon: "marker1",
      visible?: true
    },
    %Marker {
      latitude: "42.354153",
      longitude: "-71.070547",
      icon: "marker2",
      visible?: true
    },
    %Marker {
      latitude: "42.354153",
      longitude: "-71.070547",
      icon: "marker2",
      visible?: true
    }
  ]

  @paths [
    %Path {
      weight: 7,
      color: "#fff",
      polyline: "thick polyline"
    },
    %Path {
      weight: 2,
      color: "#b727",
      polyline: "thin polyline"
    }
  ]

  @map_data %MapData{
    height: 200,
    width: 300,
    markers: @markers,
    paths: @paths
  }

  describe "static_query/1" do
    @hidden_markers Enum.map(@markers, & %{&1 | visible?: false})

    test "Returns correct size param" do
      query = static_query(@map_data)
      assert Keyword.get(query, :size) == "300x200"
    end

    test "groups markers by icons" do
      single_marker = {:markers, "anchor:center|icon:marker1|42.355041,-71.066065"}
      multiple_markers = {:markers, "anchor:center|icon:marker2|42.354153,-71.070547|42.354153,-71.070547"}
      markers = @map_data |> static_query() |> Enum.filter(fn {key, _val} -> key == :markers end)
      assert List.first(markers) == multiple_markers
      assert Enum.at(markers, 1) == single_marker
    end

    test "contains center param when no visible markers are given" do
      hidden_marker_map = %{@map_data | markers: @hidden_markers}
      query = static_query(hidden_marker_map)
      assert Keyword.get(query, :center) == "42.355041,-71.066065"
    end

    test "does not return hidden markers" do
      hidden_marker_map = %{@map_data | markers: @hidden_markers}
      query = static_query(hidden_marker_map)
      refute Keyword.get(query, :markers)
    end
  end
end

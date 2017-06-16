defmodule GoogleMaps.MapData do
  alias GoogleMaps.MapData.Path
  alias GoogleMaps.MapData.Marker
  @moduledoc """
  Represents the data required to build a a google map.
  """

  defstruct [
    markers: [],
    paths: [],
    width: 0,
    height: 0,
    zoom: nil,
    scale: 1
  ]

  @type t :: %__MODULE__{
    markers: [Marker.t],
    paths: [Path.t],
    width: integer,
    height: integer,
    zoom: integer | nil,
    scale: integer
  }

  @typep static_query_key :: :markers | :path | :zoom | :scale | :center | :size
  @typep query_entry :: {static_query_key, String.t | nil}

  @doc """
  Given a MapData stuct, returns a Keyword list representing
  a static query.
  """
  @spec static_query(t) :: [query_entry]
  def static_query(map_data) do
    [
      center: center_value(map_data),
      size: size_value(map_data),
      scale: map_data.scale,
      zoom: map_data.zoom,
    ]
    |> format_static_markers(map_data.markers)
    |> format_static_paths(map_data.paths)
  end

  @spec center_value(t) :: String.t | nil
  defp center_value(map_data) do
    do_center_value(map_data, Enum.any?(map_data.markers, & &1.visible?))
  end

  @spec do_center_value(t, boolean) :: String.t | nil
  defp do_center_value(%__MODULE__{markers: [marker | _]}, false) do
    Marker.format_static_marker(marker)
  end
  defp do_center_value(_map_data, _all_hiden), do: nil

  @spec size_value(t) :: String.t
  defp size_value(%__MODULE__{width: width, height: height}), do: "#{width}x#{height}"

  def format_static_markers(params, markers) do
    markers
    |> Enum.filter(& &1.visible?)
    |> Enum.group_by(& &1.icon)
    |> Enum.map(&do_format_static_markers/1)
    |> add_values_for_key(:markers, params)
  end

  @spec do_format_static_markers({String.t | nil, [Marker.t]}) :: String.t
  defp do_format_static_markers({nil, markers}) do
    formatted_markers = Enum.map(markers, &Marker.format_static_marker/1)
    "anchor:center|#{Enum.join(formatted_markers, "|")}"
  end
  defp do_format_static_markers({icon, markers}) do
    formatted_markers = Enum.map(markers, &Marker.format_static_marker/1)
    "anchor:center|icon:#{icon}|#{Enum.join(formatted_markers, "|")}"
  end

  @spec format_static_paths([query_entry], [Path.t]) :: [query_entry]
  defp format_static_paths(params, paths) do
    paths
    |> Enum.map(&Path.format_static_path/1)
    |> add_values_for_key(:path, params)
  end

  defp add_values_for_key(values, key, params) do
    Enum.reduce(values, params, fn(value, key_list) -> [{key, value} | key_list] end)
  end
end

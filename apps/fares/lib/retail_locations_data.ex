defmodule Fares.RetailLocations.Data do
  @doc """
    Parses json from the existing data file and returns it.
  """
  alias Fares.RetailLocations.Location
  alias Stops.Position

  @spec get(String.t) :: [Location.t]
  def get(output_file \\ "fare_location_data.json") do
    output_file
    |> file_path
    |> File.read!
    |> Poison.decode!
    |> Enum.map(&atomify_keys/1)
    |> Enum.map(&struct(Location, &1))
    |> Enum.reject(&(&1.latitude == 0 || &1.longitude == 0))
  end

  @spec build_r_tree :: :rtree.rtree
  def build_r_tree do
    get()
    |> Enum.map(&build_point_from_location/1)
    |> Enum.reduce(:rstar.new(2), fn l, t -> :rstar.insert(t, l) end)
  end

  @spec k_nearest_neighbors(:rtree.rtree, Stops.Position.t, integer) :: [Location.t]
  def k_nearest_neighbors(tree, location, k) do
    query = build_point_from_location(location)

    tree
    |> :rstar.search_nearest(query, k)
    |> Enum.map(&extract_location_from_point/1)
  end

  defp extract_location_from_point(point) do
    {:geometry, 2, _coords, location} = point
    location
  end

  defp build_point_from_location(location) do
    :rstar_geometry.point2d(Position.longitude(location), Position.latitude(location), location)
  end

  @doc """
    Returns the full path to a file within the Fares app.
  """
  @spec file_path(String.t) :: String.t
  def file_path(<< ?/ >> <>  _rest_of_path = path) do
    # got a full path, use that
    path
  end
  def file_path(file) do
    :fares
    |> Application.app_dir
    |> Path.join("priv")
    |> Path.join(file)
  end

  @spec atomify_keys(map) :: [{atom, String.t}]
  defp atomify_keys(location) do
    Enum.map(location, fn {k,v} -> {String.to_atom(k), v} end)
  end
end

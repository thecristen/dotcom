defmodule Fares.RetailLocations.Data do
  @doc """
    Parses json from the existing data file and returns it.
  """
  alias Fares.RetailLocations.Location

  def file, do: "fare_location_data.json"

  @spec get(String.t) :: [Location.t]
  def get(output_file \\ file) do
    output_file
    |> file_path
    |> File.read!
    |> Poison.decode!
    |> Enum.map(&atomify_keys/1)
    |> Enum.map(&struct(Location, &1))
    |> Enum.reject(&(&1.latitude == 0 || &1.longitude == 0))
  end

  @doc """
    Returns the full path to a file within the Fares app.
  """
  @spec file_path(String.t) :: String.t
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

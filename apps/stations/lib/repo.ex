defmodule Stations.Repo do
  @moduledoc """
  Matches the Ecto API, but fetches Stations from the Station Info API instead.
  """
  def all do
    Stations.Api.all
    |> Enum.sort_by(&(&1.name))
  end

  def get!(_, id) do
    case Stations.Api.by_gtfs_id(id) do
      nil -> raise Stations.NotFoundError, message: "Could not find station #{id}"
      station -> station
    end
  end
end

defmodule Stations.NotFoundError do
  @moduledoc "Raised when we don't find a station with the given GTFS ID"
  defexception [:message]
end

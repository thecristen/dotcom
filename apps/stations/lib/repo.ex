defmodule Stations.Repo do
  @moduledoc """
  Matches the Ecto API, but fetches Stations from the Station Info API instead.
  """
  use RepoCache, ttl: :timer.hours(1)

  def all do
    cache [], fn _ ->
      Stations.Api.all
      |> Enum.sort_by(&(&1.name))
    end
  end

  def get(id) do
    cache id, &Stations.Api.by_gtfs_id/1
  end

  def get!(id) do
    case get(id) do
      nil -> raise Stations.NotFoundError, message: "Could not find station #{id}"
      station -> station
    end
  end
end

defmodule Stations.NotFoundError do
  @moduledoc "Raised when we don't find a station with the given GTFS ID"
  defexception [:message]
end

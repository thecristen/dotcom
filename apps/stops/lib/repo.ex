defmodule Stops.Repo do
  @moduledoc """
  Matches the Ecto API, but fetches Stops from the Stop Info API instead.
  """
  use RepoCache, ttl: :timer.hours(1)

  def stations do
    cache [], fn _ ->
      Stops.Api.all
      |> Enum.sort_by(&(&1.name))
    end
  end

  def get(id) do
    cache id, &Stops.Api.by_gtfs_id/1
  end

  def get!(id) do
    case get(id) do
      nil -> raise Stops.NotFoundError, message: "Could not find stop #{id}"
      stop -> stop
    end
  end

  @spec closest(float, float, integer) :: [Stop.t]
  def closest(lat, long, number \\ 12) do
    stops = V3Api.Stops.all(latitude: lat, longitude: long, radius: 1)

    stops
    |> find_closest(lat, long, number)
  end

  @spec find_closest(JsonApi.t, float, float, integer) :: [Stop.t]
  def find_closest(%JsonApi{data: stops}, lat, long, number \\ 12) do
    stops
    |> Enum.map(&position/1)
    |> Stops.Distance.sort({lat, long})
    |> Enum.take(number)
    |> Enum.map(&Stops.Repo.get(&1.id))
  end

  defp position(%JsonApi.Item{id: id, attributes: %{"latitude" => latitude,
                                                    "longitude" => longitude}}) do
    %{
      id: id,
      latitude: latitude,
      longitude: longitude
    }
  end
end

defmodule Stops.NotFoundError do
  @moduledoc "Raised when we don't find a stop with the given GTFS ID"
  defexception [:message]
end

defmodule Vehicles.Repo do
  use RepoCache, ttl: :timer.seconds(10)

  alias Vehicles.{Vehicle, Parser}

  @default_params [
    "fields[vehicle]": "direction_id,current_status,longitude,latitude",
    "fields[stop]": "",
    "include": "stop,trip"
  ]

  @spec route(String.t, Keyword.t) :: [Vehicle.t]
  def route(route_id, opts \\ []) do
    [route: route_id]
    |> Keyword.merge(opts)
    |> cache(&fetch/1)
  end

  @spec trip(String.t) :: Vehicle.t | nil
  def trip(trip_id) do
    [trip: trip_id]
    |> cache(&fetch/1)
    |> List.first
  end

  @spec fetch(keyword(String.t)) :: [Vehicle.t]
  defp fetch(params) do
    @default_params
    |> Keyword.merge(params)
    |> V3Api.Vehicles.all
    |> Map.get(:data)
    |> Enum.map(&Parser.parse/1)
  end
end

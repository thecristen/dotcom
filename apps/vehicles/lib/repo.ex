defmodule Vehicles.Repo do
  use RepoCache, ttl: :timer.seconds(10)

  alias Vehicles.{Vehicle, Parser}

  @spec route(String.t) :: [Vehicle.t]
  def route(route_id) do
    [route: route_id]
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
    params
    |> Keyword.put(:"fields[vehicle]", "direction_id,current_status")
    |> V3Api.Vehicles.all
    |> Map.get(:data)
    |> Enum.map(&Parser.parse/1)
  end
end

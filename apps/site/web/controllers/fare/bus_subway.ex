defmodule Site.FareController.BusSubway do
  use Site.FareController.Behavior
  alias Fares.Fare
  alias Site.FareController.Filter
  import Plug.Conn, only: [assign: 3]
  import Site.Router.Helpers

  def template(), do: "bus_subway.html"

  def before_render(conn) do
    conn
    |> assign(:breadcrumbs, [
          {fare_path(conn, :index), "Fares and Passes"},
          "Bus and Subway"
        ])
  end

  def fares(_conn) do
    [:subway, :bus]
    |> Enum.flat_map(&Fares.Repo.all(mode: &1))
  end

  def filters([%Fare{reduced: nil} | _] = fares) do
    {single_rides, passes} = fares |> Enum.partition(&single_ride?/1)

    [
      %Filter{
        id: "single",
        name: "One Way",
        fares: single_rides
      },
      %Filter{
        id: "passes",
        name: "Passes",
        fares: passes
      }
    ]
  end
  def filters(fares) do
    [
      %Filter{
        name: "Single Rides and Passes",
        fares: fares
      }
    ]
  end

  defp single_ride?(%Fare{duration: duration}) when duration in [:single_trip, :round_trip] do
    true
  end
  defp single_ride?(%Fare{}) do
    false
  end
end

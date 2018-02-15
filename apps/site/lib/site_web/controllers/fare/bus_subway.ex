defmodule SiteWeb.FareController.BusSubway do
  use SiteWeb.FareController.Behavior
  alias Fares.Fare
  alias Util.Breadcrumb
  alias SiteWeb.FareController.Filter
  import Plug.Conn, only: [assign: 3]
  import SiteWeb.Router.Helpers

  @impl true
  def template(), do: "bus_subway.html"

  @impl true
  def before_render(conn) do
    conn
    |> assign(:breadcrumbs, [
          Breadcrumb.build("Fares and Passes", fare_path(conn, :index)),
          Breadcrumb.build("Bus and Subway")
        ])
  end

  @impl true
  def fares(_conn) do
    [:subway, :bus]
    |> Enum.flat_map(&Fares.Repo.all(mode: &1))
    |> Enum.reject(&(&1.name == :free_fare))
  end

  @impl true
  def filters([%Fare{reduced: nil} | _] = fares) do
    {single_rides, passes} = fares |> Enum.split_with(&single_ride?/1)

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

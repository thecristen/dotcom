defmodule Site.Fare.FareBehaviour do
  @moduledoc "Behaviour for fare pages."

  @callback route_type() :: integer
  @callback mode_name() :: String.t
  @callback fares(Schedules.Stop.t, Schedules.Stop.t) :: [Fares.Fare.t]
  @callback key_stops() :: [Schedules.Stop.t]

  use Site.Web, :controller

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      use Site.Web, :controller

      def index(conn, _params) do
        unquote(__MODULE__).index(__MODULE__, conn)
      end

      def key_stops, do: []

      def origin_stops do
        unquote(__MODULE__).origin_stops(route_type)
      end

      def destination_stops(origin) do
        unquote(__MODULE__).destination_stops(origin, route_type)
      end

      defoverridable [key_stops: 0]
    end
  end

  def index(mode_strategy, conn)  do
    origin_stop_list = mode_strategy.origin_stops
    origin = get_stop(conn, "origin", origin_stop_list)

    destination_stop_list = mode_strategy.destination_stops(origin)
    destination = get_stop(conn, "destination", destination_stop_list)

    fares = mode_strategy.fares(origin, destination)

    conn
    |> render("index.html",
        mode_name: mode_strategy.mode_name,
        route_type: mode_strategy.route_type,
        origin_stops: origin_stop_list,
        destination_stops: destination_stop_list,
        fares: fares,
        key_stops: mode_strategy.key_stops,
        origin: origin,
        destination: destination,
        fare_type: fare_type(conn)
    )
  end

  def origin_stops(route_type) do
    route_type
    |> Routes.Repo.by_type
    |> Enum.flat_map(&Schedules.Repo.stops &1.id, [])
    |> Enum.sort_by(&(&1.name))
    |> Enum.dedup
  end

  def destination_stops(nil, _route_type) do
    []
  end
  def destination_stops(origin, route_type) do
    origin.id
    |> Routes.Repo.by_stop
    |> Enum.filter_map(&(&1.type == route_type), &(Schedules.Repo.stops &1.id, []))
    |> Enum.concat
    |> Enum.sort_by(&(&1.name))
    |> Enum.dedup
    |> Enum.reject(&(&1.id == origin.id))
  end

  def get_stop(conn, stop, all_stops) do
    conn.params
    |> Map.get(stop, "")
    |> (fn o -> Enum.find(all_stops, &(&1.id == o)) end).()
  end

  defp fare_type(%{params: %{"fare_type" => fare_type}}) when fare_type in ["adult", "senior_disabled", "student"] do
    fare_type
  end
  defp fare_type(_) do
    "adult"
  end
end

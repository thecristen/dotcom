defmodule Site.Fare.FareBehaviour do
  @moduledoc "Behaviour for fare pages."

  @callback route_type() :: integer
  @callback mode_name() :: String.t
  @callback fares(Plug.Conn.t) :: Plug.Conn.t
  @callback key_stops() :: [Stations.Station.t]

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
        Stations.Repo.all
        |> Enum.filter(fn station ->
          station.id
          |> Routes.Repo.by_stop
          |> Enum.filter(&(&1.type == route_type))
          |> Enum.empty?
          |> Kernel.!
        end)
      end

      def destination_stops(origin) do
        origin
        |> Routes.Repo.by_stop
        |> Enum.filter_map(&(&1.type == route_type), &(Schedules.Repo.stops &1.id, []))
        |> Enum.concat
        |> Enum.uniq
        |> Enum.sort_by(&(&1.name))
      end

      defoverridable [key_stops: 0]
    end
  end

  def index(mode_strategy, conn)  do
    conn = conn
    |> assign_params
    |> assign_fare_type
    |> mode_strategy.fares

    conn
    |> render("index.html",
        mode_name: mode_strategy.mode_name,
        origin_stops: mode_strategy.origin_stops,
        destination_stops: mode_strategy.destination_stops(conn.assigns[:origin].id),
        key_stops: mode_strategy.key_stops
      )
  end

  defp assign_params(conn) do
    Enum.reduce [:origin, :destination], conn, fn (param, conn) ->
      case Map.get(conn.params, Atom.to_string(param)) do
        "" -> assign conn, param, nil
        value -> assign conn, param, Stations.Repo.get(value)
      end
    end
  end

  defp assign_fare_type(%{params: %{"fare_type" => fare_type}} = conn) when fare_type in ["adult", "senior-disabled", "student"] do
    assign(conn, :fare_type, fare_type)
  end
  defp assign_fare_type(conn) do
    assign(conn, :fare_type, "adult")
  end
end

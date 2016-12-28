defmodule Site.FareController.OriginDestinationFareBehavior do
  @doc "Atom for the mode."
  @callback mode() :: atom()

  @callback route_type() :: integer
  @callback key_stops() :: [Schedules.Stop.t]

  alias Site.FareController.Filter
  import Plug.Conn, only: [assign: 3]
  import Site.Router.Helpers

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      use Site.FareController.Behavior

      defdelegate filters(fares), to: unquote(__MODULE__)

      def before_render(conn) do
        unquote(__MODULE__).before_render(conn, __MODULE__)
      end

      def template(), do: "origin_destination.html"

      def key_stops, do: []

      defoverridable [key_stops: 0]
    end
  end

  def before_render(conn, module) do
    origin_stop_list = origin_stops(module.route_type)
    origin = get_stop(conn, "origin", origin_stop_list)

    destination_stop_list = destination_stops(origin, module.route_type)
    destination = conn
                  |> get_stop("destination", destination_stop_list)
                  |> guess_destination(destination_stop_list)

    conn
    |> assign(:breadcrumbs, [
          {fare_path(conn, :index), "Fares and Passes"},
          Site.ViewHelpers.mode_name(module.mode)
        ])
    |> assign(:mode,  module.mode)
    |> assign(:route_type, module.route_type)
    |> assign(:origin_stops, origin_stop_list)
    |> assign(:destination_stops, destination_stop_list)
    |> assign(:key_stops, module.key_stops)
    |> assign(:origin, origin)
    |> assign(:destination, destination)
  end

  def filters([example_fare | _] = fares) do
    [
      %Filter{
        id: "",
        name: [
          Fares.Format.name(example_fare),
          " ",
          Fares.Format.customers(example_fare),
          " Fares"
        ],
        fares: fares
      }
    ]
  end
  def filters([]) do
    []
  end

  defp origin_stops(route_type) do
    route_type
    |> Routes.Repo.by_type
    |> Enum.flat_map(&Schedules.Repo.stops &1.id, [])
    |> Enum.sort_by(&(&1.name))
    |> Enum.dedup
  end

  defp destination_stops(nil, _route_type) do
    []
  end
  defp destination_stops(origin, route_type) do
    origin.id
    |> Routes.Repo.by_stop
    |> Enum.filter_map(&(&1.type == route_type), &(Schedules.Repo.stops &1.id, []))
    |> Enum.concat
    |> Enum.sort_by(&(&1.name))
    |> Enum.dedup
    |> Enum.reject(&(&1.id == origin))
  end

  @doc "Returns a destination if there is only one possibility"
  @spec guess_destination(Schedules.Stop.t | nil, [Schedules.Stop.t]) :: Schedules.Stop.t | nil
  def guess_destination(nil, [_origin, destination]) do
    destination
  end
  def guess_destination(destination, _stops) do
    destination
  end

  def get_stop(conn, stop_field, all_stops) do
    conn.params
    |> Map.get(stop_field, "")
    |> (fn o -> Enum.find(all_stops, &(&1.id == o)) end).()
  end
end

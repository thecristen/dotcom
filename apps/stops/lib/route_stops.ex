defmodule Stops.RouteStops do
  defstruct [:branch, :stops]

  @type t :: %__MODULE__{
    branch: String.t,
    stops: [Stops.RouteStop.t]
  }
  @type direction_id_t :: 0 | 1

  alias Stops.RouteStop

  @branched_routes RouteStop.branched_routes

  @doc """
  Builds a list of all stops (as %RouteStop{}) on a route in a single direction.
  """
  @spec by_direction([Stops.Stop.t], [Routes.Shape.t], Routes.Route.t, direction_id_t) :: t
  def by_direction(stops, shapes, %Routes.Route{} = route, direction_id) when is_integer(direction_id) do
    shapes
    |> get_shapes(route, direction_id)
    |> RouteStop.list_from_shapes(stops, route, direction_id)
    |> Enum.chunk_by(& &1.branch)
    |> Enum.map(fn [%RouteStop{branch: branch}|_] = stops -> %__MODULE__{branch: branch, stops: stops} end)
  end

  @doc """
  For a route in a single direction, retrieves either the primary shape for that route, or the shapes
  of all of its branches.
  """
  @spec get_shapes([Routes.Shape.t], Routes.Route.t, direction_id_t) :: [Routes.Shape.t]
  def get_shapes([], _route, _direction_id), do: []
  def get_shapes(shapes, %Routes.Route{id: "Green-E"}, _) do
    # E line only has one shape -- once the bug mentioned below gets fixed we can remove this specific check
    [Enum.find(shapes, & &1.primary?)]
  end
  def get_shapes(shapes, %Routes.Route{id: "Green-" <> _}, _) do
    # there is a funny quirk with the green line at the moment where for all but the E line, the route marked
    # primary: false is actually the one we want to use. this is probably going to get fixed soon, at which point
    # we'll need to update this.
    case shapes do
      [shape] -> [shape]
      [_|_] -> [Enum.find(shapes, & &1.primary? == false)]
    end
  end
  def get_shapes(shapes, %Routes.Route{id: "CR-Kingston"}, 0) do
    # There are a number of issues with values that the shapes API returns for Kingston.
    # - It's returning multiple shapes with the same id and stop_ids but slightly different polylines;
    # - The primary shape incorrectly has Quincy Center twice, and doesn't include Plymouth;
    # - The only shapes that include Plymouth either skip Quincy and JFK, or they also include
    #       Kingston (both of these are technically correct -- some trips on this route actually do go
    #       to Kingston, and then literally reverse direction for a bit and go down the other branch to Kingston.)
    # Because of all this, it's just easier to process Kingston separately.

    shapes
    |> Enum.uniq_by(& &1.id)
    |> Enum.filter(& &1.primary? || &1.id == "9790004")
    |> Enum.map(fn shape ->
      if shape.name == "Plymouth" do
        %{shape | stop_ids: List.delete_at(shape.stop_ids, -2)}
      else
        %{shape | stop_ids: List.delete_at(shape.stop_ids, 1)}
      end
    end)
  end
  def get_shapes(shapes, %Routes.Route{id: route_id}, 0) when route_id in @branched_routes do
    shapes
  end
  def get_shapes(shapes, %Routes.Route{id: route_id}, 1) when route_id in @branched_routes do
    # Since a shape is named for its terminus, branched route shapes all have the same name when direction_id is 1.
    # So, we have to fetch the shapes for the other direction to get the branch names.
    route_id
    |> Routes.Repo.get_shapes(0)
    |> Enum.map(& &1.name)
    |> Enum.zip(shapes)
    |> Enum.map(fn {name, shape} -> %{shape | name: name} end)
  end
  def get_shapes(shapes, _route, _direction_id), do: Enum.filter(shapes, & &1.primary?)
end

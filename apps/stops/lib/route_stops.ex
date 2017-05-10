defmodule Stops.RouteStops do
  defstruct [:branch, :stops]

  @type t :: %__MODULE__{
    branch: String.t,
    stops: [Stops.RouteStop.t]
  }
  @type direction_id_t :: 0 | 1

  alias Stops.RouteStop

  @doc """
  Builds a list of all stops (as %RouteStop{}) on a route in a single direction.
  """
  @spec by_direction([Stops.Stop.t], [Routes.Shape.t], Routes.Route.t, direction_id_t) :: t
  def by_direction(stops, shapes, %Routes.Route{} = route, direction_id) when is_integer(direction_id) do
    shapes
    |> munge_shapes(route.id, direction_id)
    |> RouteStop.list_from_shapes(stops, route, direction_id)
    |> Enum.chunk_by(& &1.branch)
    |> Enum.map(&from_list/1)
  end

  @doc """
  Backwards-compatibily hack to work with both the old (primary?) Shapes API
  and new (priority) API
  """
  @spec munge_shapes([Routes.Shape.t], Routes.Route.id_t, direction_id_t) :: [Routes.Shape.t]
  def munge_shapes(shapes, route, direction_id)
  def munge_shapes(shapes, "CR-Kingston", 0) do
    shapes
    |> Enum.filter(& &1.id in ~w(9790002 9790006)s)
    |> Enum.uniq_by(& &1.id)
  end
  def munge_shapes([first, _], "Green-E", 0) do
    [first]
  end
  def munge_shapes([_, second], "Green-" <> _, 0) do
    [second]
  end
  def munge_shapes([%{name: "Alewife"} = ashmont, braintree], "Red", 1) do
    [
      %{ashmont | name: "Ashmont"},
      %{braintree | name: "Braintree"}
    ]
  end
  def munge_shapes([%{name: "South Station"} = stoughton, wickford], "CR-Providence", 1) do
    [
      %{wickford | name: "Wickford Junction"},
      %{stoughton | name: "Stoughton"}
    ]
  end
  def munge_shapes([%{name: "South Station"} = kingston, plymouth], "CR-Kingston", 1) do
    [
      %{kingston | name: "Kingston"},
      %{plymouth | name: "Plymouth"}
    ]
  end
  def munge_shapes([%{name: "North Station"} = newburyport, rockport], "CR-Newburyport", 1) do
    [
      %{rockport | name: "Rockport"},
      %{newburyport | name: "Newburyport"},
    ]
  end
  def munge_shapes(shapes, _route, _direction_id) do
    shapes
  end

  @spec from_list([RouteStop.t]) :: t
  defp from_list([%RouteStop{branch: branch} | _] = stops) do
    %__MODULE__{
      branch: branch,
      stops: stops
    }
  end
end

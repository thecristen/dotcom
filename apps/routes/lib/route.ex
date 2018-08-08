defmodule Routes.Route do
  defstruct [
    id: "",
    type: 0,
    name: "",
    long_name: "",
    direction_names: %{0 => "Outbound", 1 => "Inbound"},
    description: :unknown,
  ]
  @type id_t :: String.t
  @type t :: %__MODULE__{
    id: id_t,
    type: 0..4,
    name: String.t,
    long_name: String.t,
    direction_names: %{0 => String.t, 1 => String.t},
    description: gtfs_route_desc,
  }
  @type gtfs_route_type :: :subway | :commuter_rail | :bus | :ferry
  @type gtfs_route_desc :: :airport_shuttle |
                           :commuter_rail |
                           :rapid_transit |
                           :local_bus |
                           :key_bus_route |
                           :limited_service |
                           :ferry |
                           :rail_replacement_bus |
                           :unknown
  @type route_type :: gtfs_route_type | :the_ride
  @type type_int :: 0..4
  @type subway_lines_type :: :orange_line | :red_line | :green_line | :blue_line | :mattapan_line
  @type branch_name :: String.t | nil

  @inner_express_routes ~w(170 325 326 351 424 426 428 434 441 442 448 449 450 459 501 502 503 504 553 554 556 558)
  @inner_express_route_set MapSet.new(@inner_express_routes)
  @outer_express_routes ~w(352 354 505)
  @outer_express_route_set MapSet.new(@outer_express_routes)
  @silver_line_rapid_transit_routes ~w(741 742 743 746)
  @silver_line_rapid_transit_route_set MapSet.new(@silver_line_rapid_transit_routes)

  @spec type_atom(t | type_int | String.t) :: gtfs_route_type
  def type_atom(%__MODULE__{type: type}), do: type_atom(type)
  def type_atom(0), do: :subway
  def type_atom(1), do: :subway
  def type_atom(2), do: :commuter_rail
  def type_atom(3), do: :bus
  def type_atom(4), do: :ferry
  def type_atom("commuter-rail"), do: :commuter_rail
  def type_atom("commuter_rail"), do: :commuter_rail
  def type_atom("subway"), do: :subway
  def type_atom("bus"), do: :bus
  def type_atom("ferry"), do: :ferry

  @spec types_for_mode(gtfs_route_type | subway_lines_type) :: [0..4]
  def types_for_mode(:subway), do: [0, 1]
  def types_for_mode(:commuter_rail), do: [2]
  def types_for_mode(:bus), do: [3]
  def types_for_mode(:ferry), do: [4]
  def types_for_mode(:green_line), do: [0]
  def types_for_mode(:green_line_b), do: [0]
  def types_for_mode(:green_line_c), do: [0]
  def types_for_mode(:green_line_d), do: [0]
  def types_for_mode(:green_line_e), do: [0]
  def types_for_mode(:red_line), do: [1]
  def types_for_mode(:blue_line), do: [1]
  def types_for_mode(:orange_line), do: [1]
  def types_for_mode(:mattapan_line), do: [0]

  @spec icon_atom(t) :: gtfs_route_type | subway_lines_type
  def icon_atom(%__MODULE__{id: "Red"}), do: :red_line
  def icon_atom(%__MODULE__{id: "Mattapan"}), do: :mattapan_line
  def icon_atom(%__MODULE__{id: "Orange"}), do: :orange_line
  def icon_atom(%__MODULE__{id: "Blue"}), do: :blue_line
  def icon_atom(%__MODULE__{id: "Green"}), do: :green_line
  def icon_atom(%__MODULE__{id: "Green-B"}), do: :green_line_b
  def icon_atom(%__MODULE__{id: "Green-C"}), do: :green_line_c
  def icon_atom(%__MODULE__{id: "Green-D"}), do: :green_line_d
  def icon_atom(%__MODULE__{id: "Green-E"}), do: :green_line_e
  def icon_atom(%__MODULE__{} = route), do: type_atom(route.type)

  @spec path_atom(t) :: gtfs_route_type
  def path_atom(%__MODULE__{type: 2}), do: :"commuter-rail"
  def path_atom(%__MODULE__{type: type}), do: type_atom(type)

  @spec type_name(atom) :: String.t
  def type_name(:the_ride), do: "The RIDE"
  for type_atom <- ~w(subway commuter_rail bus ferry
                      orange_line red_line blue_line
                      green_line green_line_b green_line_c green_line_d green_line_e
                      mattapan_trolley mattapan_line)a do
    type_string = type_atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
    def type_name(unquote(type_atom)), do: unquote(type_string)
  end

  @doc """
  Standardizes a route with branches into a generic route. Currently only changes Green Line branches.
  """
  @spec to_naive(__MODULE__.t) :: __MODULE__.t
  def to_naive(%__MODULE__{id: "Green-" <> _, type: 0} = route) do
    %{route | id: "Green", name: "Green Line"}
  end
  def to_naive(%__MODULE__{} = route) do
    route
  end

  @doc """
  A slightly more detailed version of &Route.type_name/1.
  The only difference is that route ids are listed for bus routes, otherwise it just returns &Route.type_name/1.
  """
  @spec type_summary(subway_lines_type | gtfs_route_type, [t]) :: String.t
  def type_summary(:bus, [%__MODULE__{} | _] = routes) do
    "Bus: #{bus_route_list(routes)}"
  end
  def type_summary(atom, _) do
    type_name(atom)
  end

  @spec bus_route_list([Routes.Route.t]) :: String.t
  defp bus_route_list(routes) when is_list(routes) do
    routes
    |> Enum.filter(&(icon_atom(&1) == :bus))
    |> Enum.map(&(&1.name))
    |> Enum.join(", ")
  end

  @spec direction_name(t, 0 | 1) :: String.t
  def direction_name(%__MODULE__{direction_names: names}, direction_id) when direction_id in [0, 1] do
    Map.get(names, direction_id)
  end

  @spec vehicle_name(t) :: String.t
  def vehicle_name(%__MODULE__{type: type}) when type in [0, 1, 2] do
    "Train"
  end
  def vehicle_name(%__MODULE__{type: 3}) do
    "Bus"
  end
  def vehicle_name(%__MODULE__{type: 4}) do
    "Ferry"
  end

  @spec vehicle_atom(0..4) :: atom
  def vehicle_atom(0), do: :trolley
  def vehicle_atom(1), do: :subway
  def vehicle_atom(2), do: :commuter_rail
  def vehicle_atom(3), do: :bus
  def vehicle_atom(4), do: :ferry
  def vehicle_atom(_), do: :subway

  @spec key_route?(t) :: boolean
  def key_route?(%__MODULE__{description: :key_bus_route}), do: true
  def key_route?(%__MODULE__{description: :rapid_transit}), do: true
  def key_route?(%__MODULE__{}), do: false

  defmacro subway?(type, id) do
    quote do
      unquote(type) in [0, 1] and unquote(id) != "Mattapan"
    end
  end

  def inner_express, do: @inner_express_routes
  def outer_express, do: @outer_express_routes
  def silver_line_rapid_transit, do: @silver_line_rapid_transit_routes

  def inner_express?(%__MODULE__{id: id}), do: id in @inner_express_route_set
  def outer_express?(%__MODULE__{id: id}), do: id in @outer_express_route_set
  def silver_line_rapid_transit?(%__MODULE__{id: id}), do: id in @silver_line_rapid_transit_route_set

  def silver_line_airport_stop?(%__MODULE__{id: "741"}, "17091"), do: true
  def silver_line_airport_stop?(%__MODULE__{id: "741"}, "27092"), do: true
  def silver_line_airport_stop?(%__MODULE__{id: "741"}, "17093"), do: true
  def silver_line_airport_stop?(%__MODULE__{id: "741"}, "17094"), do: true
  def silver_line_airport_stop?(%__MODULE__{id: "741"}, "17095"), do: true
  def silver_line_airport_stop?(_route, _origin_id), do: false
end

defimpl Phoenix.Param, for: Routes.Route do
  alias Routes.Route
  def to_param(%Route{id: "Green" <> _rest}), do: "Green"
  def to_param(%Route{id: id}), do: id
end

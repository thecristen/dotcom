defmodule Routes.Route do
  defstruct [
    id: "",
    type: 0,
    name: "",
    direction_names: %{0 => "Outbound", 1 => "Inbound"},
    key_route?: false
  ]
  @type t :: %__MODULE__{
    id: String.t,
    type: 0..4,
    name: String.t,
    direction_names: %{0 => String.t, 1 => String.t},
    key_route?: boolean
  }
  @type gtfs_route_type :: :subway | :commuter_rail | :bus | :ferry
  @type route_type :: gtfs_route_type | :the_ride
  @type subway_lines_type :: :orange_line | :red_line | :green_line | :blue_line | :mattapan_line

  @spec type_atom(t | 0..4) :: gtfs_route_type
  def type_atom(%Routes.Route{type: type}), do: type_atom(type)
  def type_atom(0), do: :subway
  def type_atom(1), do: :subway
  def type_atom(2), do: :commuter_rail
  def type_atom(3), do: :bus
  def type_atom(4), do: :ferry

  def type_name(:commuter_rail), do: "Commuter Rail"
  def type_name(:the_ride), do: "The Ride"
  def type_name(atom) do
    atom
    |> Atom.to_string
    |> String.capitalize
  end

  @spec key_route?(t) :: boolean
  def key_route?(%__MODULE__{key_route?: key_route?}) do
    key_route?
  end

  defmacro subway?(expr) do
    quote do
      unquote(expr) in [0, 1]
    end
  end
end

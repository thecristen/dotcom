defmodule Routes.Route do
  defstruct [
    id: "",
    type: 0,
    name: "",
    direction_names: %{0 => "Outbound", 1 => "Inbound"},
    key_route?: false
  ]
  @type id_t :: String.t
  @type t :: %__MODULE__{
    id: id_t,
    type: 0..4,
    name: String.t,
    direction_names: %{0 => String.t, 1 => String.t},
    key_route?: boolean
  }
  @type gtfs_route_type :: :subway | :commuter_rail | :bus | :ferry
  @type route_type :: gtfs_route_type | :the_ride
  @type subway_lines_type :: :orange_line | :red_line | :green_line | :blue_line | :mattapan_line

  @spec type_atom(t | 0..4) :: gtfs_route_type
  def type_atom(%__MODULE__{type: type}), do: type_atom(type)
  def type_atom(0), do: :subway
  def type_atom(1), do: :subway
  def type_atom(2), do: :commuter_rail
  def type_atom(3), do: :bus
  def type_atom(4), do: :ferry

  @spec icon_atom(t) :: gtfs_route_type | subway_lines_type
  def icon_atom(%__MODULE__{id: "Red"}), do: :red_line
  def icon_atom(%__MODULE__{id: "Mattapan"}), do: :red_line
  def icon_atom(%__MODULE__{id: "Orange"}), do: :orange_line
  def icon_atom(%__MODULE__{id: "Blue"}), do: :blue_line
  def icon_atom(%__MODULE__{id: "Green" <> _}), do: :green_line
  def icon_atom(%__MODULE__{} = route), do: type_atom(route.type)

  @spec type_name(atom) :: String.t
  def type_name(:commuter_rail), do: "Commuter Rail"
  def type_name(:the_ride), do: "The Ride"
  def type_name(atom) do
    atom
    |> Atom.to_string
    |> String.capitalize
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

  @spec key_route?(t) :: boolean
  def key_route?(%__MODULE__{key_route?: key_route?}) do
    key_route?
  end

  defmacro subway?(type, id) do
    quote do
      unquote(type) in [0, 1] and unquote(id) != "Mattapan"
    end
  end
end

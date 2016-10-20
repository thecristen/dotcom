defmodule Routes.Route do
  defstruct [
    id: "",
    type: 0,
    name: "",
    key_route?: false
  ]
  @type t :: %__MODULE__{
    id: String.t,
    type: 0..4,
    name: String.t,
    key_route?: boolean
  }
  @type route_type :: :subway | :commuter | :bus | :ferry

  @spec type_atom(t) :: route_type
  def type_atom(%Routes.Route{type: 0}), do: :subway
  def type_atom(%Routes.Route{type: 1}), do: :subway
  def type_atom(%Routes.Route{type: 2}), do: :commuter
  def type_atom(%Routes.Route{type: 3}), do: :bus
  def type_atom(%Routes.Route{type: 4}), do: :ferry

  @spec key_route?(t) :: boolean
  def key_route?(%__MODULE__{key_route?: key_route?}) do
    key_route?
  end
end

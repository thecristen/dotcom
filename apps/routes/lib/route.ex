defmodule Routes.Route do
  defstruct [:id, :type, :name, :key_route?]
  @type t :: %__MODULE__{
    id: String.t,
    type: 0..4,
    name: String.t,
    key_route?: boolean
  }

  def type_atom(%{type: 0}), do: :subway
  def type_atom(%{type: 1}), do: :subway
  def type_atom(%{type: 2}), do: :commuter_rail
  def type_atom(%{type: 3}), do: :bus
  def type_atom(%{type: 4}), do: :boat
  def type_atom(%{type: _}), do: :other
end

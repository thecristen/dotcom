defmodule Routes.Route do
  defstruct [:id, :type, :name, :key_route?]
  @type t :: %__MODULE__{
    id: String.t,
    type: 0..4,
    name: String.t,
    key_route?: boolean
  }
end

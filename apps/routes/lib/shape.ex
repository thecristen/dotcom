defmodule Routes.Shape do
  defstruct [
    id: "",
    name: "",
    stop_ids: [],
    primary?: false,
    direction_id: 0,
    polyline: ""
  ]
  @type id_t :: String.t
  @type t :: %__MODULE__{
    id: id_t,
    name: String.t,
    stop_ids: [],
    primary?: boolean,
    direction_id: 0 | 1,
    polyline: String.t
  }
end

defmodule Alerts.Banner do
  defstruct [
    id: "",
    title: "",
    description: ""
  ]

  @type t :: %__MODULE__{
    id: String.t,
    title: String.t,
    description: String.t
  }
end

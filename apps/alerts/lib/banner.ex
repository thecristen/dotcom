defmodule Alerts.Banner do
  defstruct [
    id: "",
    title: ""
  ]

  @type t :: %__MODULE__{
    id: String.t,
    title: String.t
  }
end

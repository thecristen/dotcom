defmodule Alerts.Banner do
  defstruct [
    id: "",
    title: "",
    url: nil
  ]

  @type t :: %__MODULE__{
    id: String.t,
    title: String.t,
    url: String.t | nil
  }
end

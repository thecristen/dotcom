defmodule Site.FareController.Filter do
  @type t :: %__MODULE__{
    id: atom,
    name: String.t,
    fares: [Fares.Fare.t]
  }

  defstruct [
    id: nil,
    name: "",
    fares: []
  ]
end

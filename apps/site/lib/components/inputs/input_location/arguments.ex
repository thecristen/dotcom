defmodule Site.Components.Inputs.InputLocation do
  @moduledoc """
  Component for using Google's current location API
  """

  defstruct [
    name: :location,
    name_index: :address,
    id: "location-input",
    address: "",
    address_error: "",
    placeholder: "Enter a location",
    submit: true,
    required: true,
    class: ""
  ]

  @type t :: %__MODULE__{
    name: atom,
    name_index: atom,
    id: String.t,
    address: String.t,
    address_error: String.t,
    placeholder: String.t,
    submit: boolean,
    required: boolean,
    class: String.t
  }
end

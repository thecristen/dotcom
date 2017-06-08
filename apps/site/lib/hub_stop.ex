defmodule HubStop do
  @moduledoc """
  Represents a HubStop, which contains an image path and and a detailedStop
  """

  defstruct [
    detailed_stop: %DetailedStop{},
    image_path: "",
    alt_text: ""
  ]

  @type t :: %__MODULE__{
    detailed_stop: DetailedStop.t,
    image_path: String.t,
    alt_text: String.t
  }
end

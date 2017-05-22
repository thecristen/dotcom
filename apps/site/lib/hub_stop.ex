defmodule HubStop do
  @moduledoc """
  Represents a HubStop, which contains an image path and and a detailedStop
  """

  defstruct [
    detailed_stop: %DetailedStop{},
    image_path: ""
  ]

  @type t :: %__MODULE__{
    detailed_stop: DetailedStop.t,
    image_path: String.t
  }
end

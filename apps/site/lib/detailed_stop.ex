defmodule DetailedStop do
  @moduledoc """
  Represents a stop and associated features
  """
  alias Stops.Stop

  defstruct [
    stop: %Stop{},
    features: [],
  ]

  @type t :: %__MODULE__{
    stop: Stop.t,
    features: [Routes.Repo.stop_features]
  }
end

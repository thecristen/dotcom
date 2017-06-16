defmodule GoogleMaps.MapData.Path do
  @moduledoc """
  Represents a google map polyline path
  """

  defstruct [
    weight: 5,
    color: "",
    polyline: ""
  ]

  @type t :: %__MODULE__{
    weight: integer,
    color: String.t,
    polyline: String.t
  }

  @doc "formats a single path for a static map url"
  @spec format_static_path(t) :: String.t
  def format_static_path(path) do
    "weight:#{path.weight}|color:#{path.color}|enc:#{path.polyline}"
  end
end

defmodule GoogleMaps.MapData.Path do
  @moduledoc """
  Represents a google map polyline path
  """

  defstruct [
    polyline: "",
    color: "",
    weight: 5
  ]

  @type t :: %__MODULE__{
    polyline: String.t,
    color: String.t,
    weight: integer
  }

  def new(polyline, color \\ "", weight \\ 5) do
    %__MODULE__{
      polyline: polyline,
      color: color,
      weight: weight
    }
  end

  @doc "formats a single path for a static map url"
  @spec format_static_path(t) :: String.t
  def format_static_path(path) do
    "weight:#{path.weight}|color:#{path.color}|enc:#{path.polyline}"
  end
end

defmodule Leaflet.MapData.Marker do
  @moduledoc """
  Represents a leaflet map marker.
  """

  @default_opts [icon: nil, tooltip: nil]

  defstruct id: nil,
            latitude: 0.0,
            longitude: 0.0,
            icon: nil,
            tooltip: nil

  @type t :: %__MODULE__{
          id: integer | nil,
          latitude: float,
          longitude: float,
          icon: String.t() | nil,
          tooltip: String.t() | nil
        }

  def new(latitude, longitude, opts \\ []) do
    map_options = Keyword.merge(@default_opts, opts)

    %__MODULE__{
      id: map_options[:id],
      latitude: latitude,
      longitude: longitude,
      icon: map_options[:icon],
      tooltip: map_options[:tooltip]
    }
  end
end

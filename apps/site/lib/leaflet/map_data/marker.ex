defmodule Leaflet.MapData.Marker do
  @moduledoc """
  Represents a leaflet map marker.
  """

  @default_opts [icon: nil, tooltip: ""]

  defstruct id: nil,
            latitude: 0.0,
            longitude: 0.0,
            icon: nil,
            tooltip: "",
            size: nil

  @type t :: %__MODULE__{
          id: integer | String.t() | nil,
          latitude: float,
          longitude: float,
          icon: String.t() | nil,
          tooltip: String.t(),
          size: [integer] | nil
        }

  def new(latitude, longitude, opts \\ []) do
    map_options = Keyword.merge(@default_opts, opts)

    %__MODULE__{
      id: map_options[:id],
      latitude: latitude,
      longitude: longitude,
      icon: map_options[:icon],
      size: map_options[:size],
      tooltip: map_options[:tooltip]
    }
  end
end

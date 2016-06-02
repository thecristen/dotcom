defmodule Stations.Station do
  @moduledoc """
  Domain model for a station.
  """
  defstruct [:id, :name, :note, :accessibility, :address, :parkings]
end

defmodule Stations.Station.Parking do
  @moduledoc """
  A type of a parking at a station.
  """
  defstruct [:type, :spots, :rate, :note]
end

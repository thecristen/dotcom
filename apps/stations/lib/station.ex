defmodule Stations.Station do
  @moduledoc """
  Domain model for a station.
  """
  defstruct [:id, :name, :note, :accessibility, :address, :parking_lots, :latitude, :longitude]
end

defmodule Stations.Station.ParkingLot do
  @moduledoc """
  A group of parking spots at a station.
  """
  defstruct [:name, :spots, :average_availability, :rate, :note, :manager]
end

defmodule Stations.Station.Parking do
  @moduledoc """
  A type of a parking at a station.
  """
  defstruct [:type, :spots, :rate, :note, :manager]
end

defmodule Stations.Station.Manager do
  @moduledoc """
  A manager of parking.
  """
  defstruct [:name, :phone, :email, :website]
end

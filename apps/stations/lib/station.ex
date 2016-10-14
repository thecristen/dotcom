defmodule Stations.Station do
  @moduledoc """
  Domain model for a station.
  """
  alias Stations.Station

  defstruct [:id, :name, :note, :accessibility, :address, :parking_lots, :latitude, :longitude, :images]
  @type t :: %Station{
    id: String.t,
    name: String.t,
    note: String.t,
    accessibility: [String.t],
    address: String.t,
    parking_lots: [Station.ParkingLot.t],
    latitude: float,
    longitude: float,
    images: [Station.Image.t]
  }
end

defmodule Stations.Station.ParkingLot do
  @moduledoc """
  A group of parking spots at a station.
  """
  defstruct [:name, :spots, :average_availability, :rate, :note, :manager]
  @type t :: %Stations.Station.ParkingLot{
    name: String.t,
    spots: [Stations.Station.Parking],
    average_availability: float,
    rate: String.t,
    note: String.t,
    manager: Stations.Station.Manager.t | nil
  }
end

defmodule Stations.Station.Parking do
  @moduledoc """
  A type of a parking at a station.
  """
  defstruct [:type, :spots, :rate, :note, :manager]
  @type t :: %Stations.Station.Parking{
    type: String.t,
    spots: non_neg_integer,
    rate: String.t,
    note: String.t,
    manager: Stations.Station.Manager.t | nil
  }
end

defmodule Stations.Station.Manager do
  @moduledoc """
  A manager of a parking lot.
  """
  defstruct [:name, :phone, :email, :website]
  @type t :: %Stations.Station.Manager{
    name: String.t,
    phone: String.t,
    email: String.t,
    website: String.t
  }
end

defmodule Stations.Station.Image do
  @moduledoc """
  A picture/PDF of the station.
  """
  defstruct [:description, :url, :sort_order]
  @type t :: %Stations.Station.Image{
    description: String.t,
    url: String.t,
    sort_order: non_neg_integer
  }
end

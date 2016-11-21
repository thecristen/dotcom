defmodule Stops.Stop do
  @moduledoc """
  Domain model for a Stop.
  """
  alias Stops.Stop

  defstruct [
    id: nil,
    name: nil,
    note: nil,
    accessibility: [],
    address: nil,
    parking_lots: [],
    latitude: nil,
    longitude: nil,
    images: [],
    station?: false,
    has_fare_machine?: false,
    has_charlie_card_vendor?: false]

  @type t :: %Stop{
    id: String.t,
    name: String.t,
    note: String.t,
    accessibility: [String.t],
    address: String.t,
    parking_lots: [Stop.ParkingLot.t],
    latitude: float,
    longitude: float,
    images: [Stop.Image.t],
    station?: boolean,
    has_fare_machine?: boolean,
    has_charlie_card_vendor?: boolean
  }

  defimpl Stops.Position do
    def latitude(stop), do: stop.latitude
    def longitude(stop), do: stop.longitude
  end
end

defmodule Stops.Stop.ParkingLot do
  @moduledoc """
  A group of parking spots at a Stop.
  """
  defstruct [:name, :spots, :average_availability, :rate, :note, :manager]
  @type t :: %Stops.Stop.ParkingLot{
    name: String.t,
    spots: [Stops.Stop.Parking],
    average_availability: float,
    rate: String.t,
    note: String.t,
    manager: Stops.Stop.Manager.t | nil
  }
end

defmodule Stops.Stop.Parking do
  @moduledoc """
  A type of a parking at a Stop.
  """
  defstruct [:type, :spots, :rate, :note, :manager]
  @type t :: %Stops.Stop.Parking{
    type: String.t,
    spots: non_neg_integer,
    rate: String.t,
    note: String.t,
    manager: Stops.Stop.Manager.t | nil
  }
end

defmodule Stops.Stop.Manager do
  @moduledoc """
  A manager of a parking lot.
  """
  defstruct [:name, :phone, :email, :website]
  @type t :: %Stops.Stop.Manager{
    name: String.t,
    phone: String.t,
    email: String.t,
    website: String.t
  }
end

defmodule Stops.Stop.Image do
  @moduledoc """
  A picture/PDF of the Stop.
  """
  defstruct [:description, :url, :sort_order]
  @type t :: %Stops.Stop.Image{
    description: String.t,
    url: String.t,
    sort_order: non_neg_integer
  }
end

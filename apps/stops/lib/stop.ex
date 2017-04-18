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
    station?: false,
    has_fare_machine?: false,
    has_charlie_card_vendor?: false]

  @type id_t :: String.t
  @type t :: %Stop{
    id: id_t,
    name: String.t,
    note: String.t,
    accessibility: [String.t],
    address: String.t,
    parking_lots: [Stop.ParkingLot.t],
    latitude: float,
    longitude: float,
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
  defstruct [:spots, :rate, :note, :manager]
  @type t :: %Stops.Stop.ParkingLot{
    spots: [Stops.Stop.Parking],
    rate: String.t,
    note: String.t,
    manager: Stops.Stop.Manager.t
  }
end

defmodule Stops.Stop.Parking do
  @moduledoc """
  A type of a parking at a Stop.
  """
  defstruct [:type, :spots]
  @type t :: %Stops.Stop.Parking{
    type: String.t,
    spots: non_neg_integer,
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

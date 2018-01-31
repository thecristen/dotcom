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
    has_charlie_card_vendor?: false,
    closed_stop_info: nil]

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
    has_charlie_card_vendor?: boolean,
    closed_stop_info: Stop.ClosedStopInfo.t | nil
  }

  defimpl Util.Position do
    def latitude(stop), do: stop.latitude
    def longitude(stop), do: stop.longitude
  end

  @doc """
  Returns a boolean indicating whether we know the accessibility status of the stop.
  """
  @spec accessibility_known?(t) :: boolean
  def accessibility_known?(%__MODULE__{accessibility: ["unknown" | _]}), do: false
  def accessibility_known?(%__MODULE__{}), do: true

  @doc """
  Returns a boolean indicating whether we consider the stop accessible.

  A stop can have accessibility features but not be considered accessible.
  """
  @spec accessible?(t) :: boolean
  def accessible?(%__MODULE__{accessibility: ["accessible" | _]}), do: true
  def accessible?(%__MODULE__{}), do: false
end

defmodule Stops.Stop.ParkingLot do
  @moduledoc """
  A group of parking spots at a Stop.
  """
  defstruct [:spots, :rate, :note, :manager, :pay_by_phone_id]
  @type t :: %Stops.Stop.ParkingLot{
    spots: [Stops.Stop.Parking],
    rate: String.t,
    note: String.t,
    manager: Stops.Stop.Manager.t,
    pay_by_phone_id: String.t
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

defmodule Stops.Stop.ClosedStopInfo do
  @moduledoc """
  Information about stations not in API data.
  """
  defstruct [
    reason: "",
    info_link: ""]

  @type t :: %Stops.Stop.ClosedStopInfo{
    reason: String.t,
    info_link: String.t
  }
end

defmodule Schedules.Schedule do
  defstruct route: nil, trip: nil, stop: nil, time: nil, flag?: false, pickup_type: 0
  @type t :: %Schedules.Schedule{
    route: Routes.Route.t,
    trip: Schedules.Trip.t,
    stop: Schedules.Stop.t,
    time: DateTime.t,
    flag?: boolean,
    pickup_type: integer
  }

  def flag?(%Schedules.Schedule{flag?: value}), do: value
end

defmodule Schedules.Trip do
  defstruct [:id, :name, :headsign, :direction_id]
  @type t :: %Schedules.Trip{
    id: String.t,
    name: String.t,
    headsign: String.t,
    direction_id: 0 | 1
  }
end

defmodule Schedules.Stop do
  defstruct [:id, :name]
  @type t :: %Schedules.Stop{
    id: String.t,
    name: String.t
  }
end

defmodule Schedules.Frequency do
  defstruct [
    time_block: nil,
    min_headway: :infinity,
    max_headway: :infinity
  ]

  @type t :: %Schedules.Frequency{
    time_block: atom,
    min_headway: integer | :infinity,
    max_headway: integer | :infinity
  }

  @doc """
  True if the block has headways during the timeframe.
  """
  @spec has_service?(t) :: boolean
  def has_service?(%Schedules.Frequency{min_headway: :infinity}) do
    false
  end
  def has_service?(%Schedules.Frequency{}) do
    true
  end
end

defmodule Schedules.FrequencyList do
  defstruct [
    frequencies: [],
    first_departure: nil,
    last_departure: nil
  ]

  @type t :: %Schedules.FrequencyList {
    frequencies: [Schedules.Frequency.t],
    first_departure: DateTime.t | nil,
    last_departure: DateTime.t | nil
  }
end

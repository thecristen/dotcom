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

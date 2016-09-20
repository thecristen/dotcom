defmodule Schedules.Schedule do
  defstruct route: nil, trip: nil, stop: nil, time: nil, flag?: false

  def flag?(%Schedules.Schedule{flag?: value}), do: value
end

defmodule Schedules.Trip do
  defstruct [:id, :name, :headsign, :direction_id]
end

defmodule Schedules.Stop do
  defstruct [:id, :name]
end

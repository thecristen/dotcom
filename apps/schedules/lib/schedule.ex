defmodule Schedules.Schedule do
  defstruct [:route, :trip, :stop, :time]
end

defmodule Schedules.Trip do
  defstruct [:id, :name, :headsign]
end

defmodule Schedules.Stop do
  defstruct [:id, :name]
end

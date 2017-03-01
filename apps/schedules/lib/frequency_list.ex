defmodule Schedules.FrequencyList do
  defstruct [
    frequencies: [],
    departures: %Schedules.Departures{}
  ]

  @type t :: %Schedules.FrequencyList {
    frequencies: [Schedules.Frequency.t],
    departures: Schedules.Departures.t
  }

  @spec build_frequency_list([Schedule.t]) :: Schedules.FrequencyList.t
  def build_frequency_list(schedules) do
    %Schedules.FrequencyList{frequencies: TimeGroup.frequency_by_time_block(schedules),
                             departures: %Schedules.Departures{
                               first_departure: List.first(schedules).time,
                               last_departure: List.last(schedules).time}}
  end
end

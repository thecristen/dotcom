defmodule Schedules.Departures do
  defstruct [
    first_departure: nil,
    last_departure: nil
  ]

  @type t :: %__MODULE__{
    first_departure: DateTime.t | nil,
    last_departure: DateTime.t | nil
  }

  @doc """
  Given a list of schedules, returns the first and last times.
  """
  @spec first_and_last_departures([Schedules.Schedule.t]) :: __MODULE__.t
  def first_and_last_departures(schedules) do
    {first, last} = Enum.min_max_by(schedules, & &1.time, fn -> {%{time: nil}, %{time: nil}} end)

    %__MODULE__{
      first_departure: first.time,
      last_departure: last.time
    }
  end

  @doc """
  Formats a Schedules.Departures.t to a human-readable time range.
  """
  @spec display_departures(__MODULE__.t) :: iodata
  def display_departures(%__MODULE__{first_departure: nil, last_departure: nil}) do
    "No Service"
  end
  def display_departures(departures) do
    [
      Timex.format!(departures.first_departure, "{kitchen}"),
      "-",
      Timex.format!(departures.last_departure, "{kitchen}")
    ]
  end
end

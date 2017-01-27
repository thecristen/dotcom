defmodule TripTime do
  @moduledoc """
  TODO://
  """
  alias Schedules.Schedule
  alias Predictions.Prediction

  @enforce_keys [:schedule]
  defstruct [:schedule, :prediction]
  @type t :: %__MODULE__{
    schedule: Schedule.t,
    prediction: Prediction.t | nil
  }

  def build(predictions, schedules) do
    schedule_map = Map.new(schedules, &({&1.stop.id, &1}))
    prediction_map = Map.new(predictions, &({&1.stop_id, &1}))

    Map.keys(schedule_map)
    |> Enum.map(&{Map.get(schedule_map, &1), Map.get(prediction_map, &1)})
    |> Enum.sort_by(&(elem(&1, 0).time))
    |> Enum.map(& %TripTime{schedule: elem(&1, 0), prediction: elem(&1, 1)})
  end
end

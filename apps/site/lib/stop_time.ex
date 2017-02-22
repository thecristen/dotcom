defmodule StopTime do
  @moduledoc """
  Represents a schedule at a stop (origin or destination) or a pair of stops (origin and destination)
  """
  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip}

  defstruct [:departure, :arrival, :trip]
  @type t :: %__MODULE__{
    departure: PredictedSchedule.t,
    arrival: PredictedSchedule.t | nil,
    trip: Trip.t | nil
  }

  @spec has_departure_schedule?(StopTime.t) :: boolean
  def has_departure_schedule?(%StopTime{departure: departure}), do: PredictedSchedule.has_schedule?(departure)
  def has_departure_schedule?(%StopTime{}), do: false

  @spec has_departure_prediction?(StopTime.t) :: boolean
  def has_departure_prediction?(%StopTime{departure: departure}) when not is_nil(departure) do
    PredictedSchedule.has_prediction?(departure)
  end
  def has_departure_prediction?(%StopTime{}), do: false

  @spec has_arrival_prediction?(StopTime.t) :: boolean
  def has_arrival_prediction?(%StopTime{arrival: arrival}) when not is_nil(arrival) do
    PredictedSchedule.has_prediction?(arrival)
  end
  def has_arrival_prediction?(%StopTime{}), do: false

  @spec has_prediction?(StopTime.t) :: boolean
  def has_prediction?(stop_time), do: has_departure_prediction?(stop_time) or has_arrival_prediction?(stop_time)


  @spec time(t) :: DateTime.t | nil
  def time(stop_time), do: departure_time(stop_time)

  @spec departure_time(StopTime.t) :: DateTime.t | nil
  def departure_time(%StopTime{departure: nil}), do: nil
  def departure_time(%StopTime{departure: departure}), do: PredictedSchedule.time(departure)

  @spec arrival_time(StopTime.t) :: DateTime.t | nil
  def arrival_time(%StopTime{arrival: nil}), do: nil
  def arrival_time(%StopTime{arrival: arrival}), do: PredictedSchedule.time(arrival)

  @spec departure_prediction_time(StopTime.t) :: DateTime.t | nil
  def departure_prediction_time(%StopTime{departure: %PredictedSchedule{prediction: %Prediction{time: time}}}), do: time
  def departure_prediction_time(%StopTime{}), do: nil
  def departure_prediction_time(nil), do: nil

  @spec departure_schedule_time(StopTime.t) :: DateTime.t | nil
  def departure_schedule_time(%StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: time}}}), do: time
  def departure_schedule_time(%StopTime{}), do: nil
  def departure_schedule_time(nil), do: nil

  def departure_schedule_before?(%StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: time}}}, cmp_time)
      when not is_nil(time) do
    Timex.before?(time, cmp_time)
  end
  def departure_schedule_before?(%StopTime{}), do: false

  def departure_schedule_after?(%StopTime{departure: %PredictedSchedule{schedule: %Schedule{time: time}}}, cmp_time)
      when not is_nil(time) do
    Timex.after?(time, cmp_time)
  end
  def departure_schedule_after?(%StopTime{}), do: false

  def before?(left, right) do
    left_departure_time = StopTime.departure_time(left)
    right_departure_time = StopTime.departure_time(right)
    left_arrival_time = StopTime.arrival_time(left)
    right_arrival_time = StopTime.arrival_time(right)

    cmp_departure =
      if (is_nil(left_departure_time) or is_nil(right_departure_time)) do
          0
      else
        Timex.compare(left_departure_time, right_departure_time)
      end

    cond do
      cmp_departure == -1 ->
        true
      cmp_departure == 1 ->
        false
      is_nil(left_arrival_time) ->
        true
      is_nil(right_arrival_time) ->
        false
      true ->
        !Timex.after?(left_arrival_time, right_arrival_time)
    end
  end

  @doc """
  Returns a message containing the maximum delay between scheduled and predicted times for an arrival
  and departure, or the empty string if there's no delay.
  """
  @spec display_status(PredictedSchedule.t | nil, PredictedSchedule.t | nil) :: iodata
  def display_status(departure, arrival \\ nil)
  def display_status(%PredictedSchedule{schedule: _, prediction: %Prediction{status: status, track: track}}, _) when not is_nil(status) do
    status = String.capitalize(status)
    case track do
      nil -> status
      track -> [status, " on track&nbsp;", track]
    end
  end
  def display_status(departure, arrival) do
    case Enum.max([delay(departure), delay(arrival)]) do
      delay when delay > 0 ->
        [ "Delayed ", Integer.to_string(delay), " ", Inflex.inflect("minute", delay) ]
      _ ->
        ""
    end
  end

  @doc """
  Returns the time difference between a schedule and prediction. If either is nil, returns 0.
  """
  @spec delay(PredictedSchedule.t | nil) :: integer
  def delay(nil), do: 0
  def delay(%PredictedSchedule{schedule: schedule, prediction: prediction}) when is_nil(schedule) or is_nil(prediction), do: 0
  def delay(%PredictedSchedule{schedule: schedule, prediction: prediction}) do
    Timex.diff(prediction.time, schedule.time, :minutes)
  end
end

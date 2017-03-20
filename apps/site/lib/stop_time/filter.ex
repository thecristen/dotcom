defmodule StopTime.Filter do
  @moduledoc """
  Helpful functions for filtering and sorting StopTimes
  """

  @type filter_flag_t :: :last_trip_and_upcoming | :predictions_then_schedules

  # Max amount of trips that should be displayed
  @trip_limit 14

  # filter the stop times based on the filter_flag
  # Currently, the following options are supported:
  # * :last_trip_and_upcoming -- only leave upcoming trips and one before (used for Commuter Rail and Ferry)
  # * :predictions_then_schedules -- remove all scheduled trips before predictions.
  #                                  That is, make sure the list starts with predictions, followed by schedules
  #
  @spec filter([StopTime.t], filter_flag_t, DateTime.t | nil) :: [StopTime.t]
  def filter(stop_times, _filter_flag, nil), do: stop_times
  def filter(stop_times, :last_trip_and_upcoming, current_time) do
    remove_departure_schedules_before_last_trip(stop_times, current_time)
  end
  def filter(stop_times, :predictions_then_schedules, current_time) do
    remove_departure_schedules_before_predictions(stop_times, current_time)
  end

  # remove all stop_times without predictions (that just have schedule) before the predicted ones
  @spec remove_departure_schedules_before_predictions([StopTime.t], DateTime.t | nil) :: [StopTime.t]
  def remove_departure_schedules_before_predictions(stop_times, current_time) do
    max_prediction_time = find_max_departure_prediction_time(stop_times)

    if max_prediction_time do
      remove_departure_schedules_before(stop_times, max_prediction_time)
    else
      remove_departure_schedules_before_last_trip(stop_times, current_time)
    end
  end

  # remove all stop times without predictions before `current_time`
  # except for the most recent one
  @spec remove_departure_schedules_before_last_trip([StopTime.t], DateTime.t | nil) :: [StopTime.t]
  def remove_departure_schedules_before_last_trip(stop_times, current_time) do
    last_trip_time = find_max_earlier_departure_schedule_time(stop_times, current_time)

    if last_trip_time do
      remove_departure_schedules_before(stop_times, last_trip_time)
    else
      stop_times
    end
  end

  @spec find_max_departure_prediction_time([StopTime.t]) :: DateTime.t | nil
  def find_max_departure_prediction_time(stop_times) do
    stop_times
    |> Enum.max_by(&StopTime.departure_prediction_time/1, fn -> nil end)
    |> StopTime.departure_prediction_time
  end


  # find the maximum scheduled departure before given time
  @spec find_max_earlier_departure_schedule_time([StopTime.t], DateTime.t) :: DateTime.t | nil
  def find_max_earlier_departure_schedule_time(stop_times, time) do
    only_past_schedules = stop_times
    |> Enum.reject(&is_nil(&1))
    |> Enum.filter(&StopTime.has_departure_schedule?(&1))
    |> Enum.reject(&StopTime.departure_schedule_after?(&1, time))

    if only_past_schedules == stop_times do
      nil
    else
      only_past_schedules
      |> Enum.max_by(&StopTime.departure_schedule_time(&1), fn -> nil end)
      |> StopTime.departure_schedule_time
    end
  end

  @spec remove_departure_schedules_before([StopTime.t], DateTime.t) :: [StopTime.t]
  def remove_departure_schedules_before(stop_times, nil), do: stop_times
  def remove_departure_schedules_before(stop_times, time) do
    stop_times
    |> Enum.reject(&is_nil(&1))
    |> Enum.filter(&StopTime.has_prediction?(&1) or not StopTime.departure_schedule_before?(&1, time))
  end

  def sort(stop_times) do
    Enum.sort(stop_times, &StopTime.before?/2)
  end

  @doc """
  Limits the amount of stop times if the keep_all? flag is set to false
  """
  @spec limit([StopTime.t], boolean) :: [StopTime.t]
  def limit(stop_times, true), do: stop_times
  def limit(stop_times, false) do
    Enum.take(stop_times, @trip_limit)
  end

  @doc """
  Determines whether the filtered times are expanded, collapsed, or neither.
  """
  @spec expansion([StopTime.t], [StopTime.t], boolean) :: :expanded | :collapsed | :none
  def expansion(expanded_times, collapsed_times, keep_all?) do
    cond do
      length(expanded_times) == length(collapsed_times) -> :none
      keep_all? -> :expanded
      true -> :collapsed
    end
  end
end

defmodule PredictedSchedule.Display do
  import Phoenix.HTML.Tag, only: [tag: 1, content_tag: 2, content_tag: 3]
  import Site.ViewHelpers, only: [fa: 1, format_schedule_time: 1]
  alias Schedules.Schedule
  alias Predictions.Prediction

  @doc """
  Returns the HTML to display a PredictedSchedule's time.

  For the commuter rail:
  If scheduled and predicted times differ, displays the scheduled time crossed out, with the predicted
  time below it. Otherwise just displays the time as below.

  Other modes:
  Display Prediction time with rss icon if available. Otherwise display scheduled time.

  """
  @spec time(PredictedSchedule.t) :: Phoenix.HTML.safe | String.t
  def time(%PredictedSchedule{} = ps) do
    ps
    |> maybe_route
    |> time_display_function()
    |> apply([ps])
  end

  @doc """
  Returns the HTML to display a PredictedSchedules time as a differece from
  the given time

  Times with a difference under 60 minutes are shown as a difference in minutes,
  a difference over 60 minutes will show the time.
  If a prediction status is available, that will be shown instead of time or
  time difference
  """
  @spec time_difference(PredictedSchedule.t, DateTime.t) :: Phoenix.HTML.Safe.t
  def time_difference(%PredictedSchedule{prediction: %Prediction{status: status}}, _current_time) when not is_nil(status) do
    do_realtime(status)
  end
  def time_difference(%PredictedSchedule{schedule: %Schedule{} = schedule, prediction: nil}, current_time) do
    do_time_difference(schedule.time, current_time)
  end
  def time_difference(%PredictedSchedule{prediction: prediction} = ps, current_time) do
    case prediction do
      %Prediction{time: time} when not is_nil(time) ->
        time
        |> do_time_difference(current_time)
        |> do_realtime()
      _ ->
        do_display_time(ps)
    end
  end

  defp do_time_difference(time, current_time) do
    time
    |> Timex.diff(current_time, :minutes)
    |> format_time_difference(time)
  end

  defp format_time_difference(diff, time) when diff > 60 or diff < -1, do: format_schedule_time(time)
  defp format_time_difference(0, _), do: "< 1 min"
  defp format_time_difference(diff, _), do: [Integer.to_string(diff), " ", Inflex.inflect("min", diff)]

  @doc """

  Returns the headsign for the PredictedSchedule.  The headsign is generally
  the destination of the train: what's displayed on the front of the
  bus/train.

  """
  @spec headsign(PredictedSchedule.t) :: String.t
  def headsign(%PredictedSchedule{schedule: nil, prediction: nil}) do
    ""
  end
  def headsign(%PredictedSchedule{} = ps) do
    case PredictedSchedule.trip(ps) do
      nil -> ps |> PredictedSchedule.route |> do_route_headsign(ps.prediction.direction_id)
      trip -> trip.headsign
    end
  end

  defp maybe_route(%PredictedSchedule{schedule: nil, prediction: nil}) do
    nil
  end
  defp maybe_route(ps) do
    PredictedSchedule.route(ps)
  end

  defp time_display_function(%Routes.Route{type: 2}) do
    &do_display_commuter_rail_time/1
  end
  defp time_display_function(_) do
    &do_display_time/1
  end

  defp do_display_commuter_rail_time(%PredictedSchedule{schedule: schedule, prediction: prediction} = ps) do
    if PredictedSchedule.minute_delay?(ps) do
      content_tag :span, do: [
        content_tag(:del, format_schedule_time(schedule.time), class: "no-wrap"),
        tag(:br),
        display_prediction(prediction)
      ]
    else
      # otherwise just show the scheduled or predicted time as appropriate
      do_display_time(ps)
    end
  end

  defp do_display_time(%PredictedSchedule{schedule: nil, prediction: nil}), do: ""
  defp do_display_time(%PredictedSchedule{schedule: scheduled, prediction: nil}) do
    content_tag :span do
      format_schedule_time(scheduled.time)
    end
  end
  defp do_display_time(%PredictedSchedule{
        schedule: %Schedule{} = schedule,
        prediction: %Prediction{time: nil, schedule_relationship: relationship}})
  when relationship in [:cancelled, :skipped] do
    content_tag :del, schedule.time |> format_schedule_time |> do_realtime
  end
  defp do_display_time(%PredictedSchedule{prediction: %Prediction{time: nil, status: nil}}) do
    ""
  end
  defp do_display_time(%PredictedSchedule{prediction: %Prediction{time: nil, status: status}}) do
    do_realtime(status)
  end
  defp do_display_time(%PredictedSchedule{prediction: prediction}) do
    display_prediction(prediction)
  end

  defp do_realtime(content) do
    content_tag(:span, [fa("rss"),
                        " ",
                       content], class: "no-wrap")
  end

  defp do_route_headsign(%Routes.Route{id: "Green-B"}, 0) do
    "Boston College"
  end
  defp do_route_headsign(%Routes.Route{id: "Green-C"}, 0) do
    "Cleveland Circle"
  end
  defp do_route_headsign(%Routes.Route{id: "Green-D"}, 0) do
    "Riverside"
  end
  defp do_route_headsign(%Routes.Route{id: "Green-E"}, 0) do
    "Heath Street"
  end
  defp do_route_headsign(_, _) do
    ""
  end

  defp display_prediction(prediction) do
    prediction.time
    |> format_schedule_time
    |> do_realtime
  end
end

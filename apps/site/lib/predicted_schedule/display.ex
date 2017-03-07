defmodule PredictedSchedule.Display do
  import Phoenix.HTML.Tag, only: [tag: 1, content_tag: 2, content_tag: 3]
  import Site.ViewHelpers, only: [fa: 1, format_schedule_time: 1]
  alias Predictions.Prediction

  @doc """
  Returns the HTML to display a PredictedSchedule's time.

  For the commuter rail:
  If scheduled and predicted times differ, displays the scheduled time crossed out, with the predicted
  time below it. Otherwise just displays the time as below.

  Other modes:
  Display Prediction time with rss icon if available. Otherwise display scheduled time.

  """
  @spec time(PredictedSchedule.t) :: Phoenix.HTML.Safe.t | String.t
  def time(%PredictedSchedule{} = ps) do
    ps
    |> maybe_route
    |> time_display_function()
    |> apply([ps])
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
    case PredictedSchedule.delay(ps) do
      # if we're going to show both, make sure they are different times
      delay when delay > 0 ->
        content_tag :span, do: [
          content_tag(:del, format_schedule_time(schedule.time), class: "no-wrap"),
          tag(:br),
          prediction.time |> format_schedule_time |> do_realtime
      ]
        # otherwise just show the scheduled or predicted time as appropriate
        _ -> do_display_time(ps)
    end
  end

  defp do_display_time(%PredictedSchedule{schedule: nil, prediction: nil}), do: ""
  defp do_display_time(%PredictedSchedule{schedule: scheduled, prediction: nil}) do
    content_tag :span do
      format_schedule_time(scheduled.time)
    end
  end
  defp do_display_time(%PredictedSchedule{prediction: %Prediction{time: nil, status: nil}}) do
    ""
  end
  defp do_display_time(%PredictedSchedule{prediction: %Prediction{time: nil, status: status}}) do
    do_realtime(status)
  end
  defp do_display_time(%PredictedSchedule{prediction: prediction}) do
    prediction.time
    |> format_schedule_time
    |> do_realtime
  end

  defp do_realtime(content) do
    content_tag(:span, [fa("rss"),
                        " ",
                       content], class: "no-wrap")
  end
end

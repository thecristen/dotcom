defmodule Site.EventView do
  use Site.Web, :view
  import Site.TimeHelpers
  import Site.ContentHelpers, only: [content: 1]

  @spec shift_date_range(String.t, integer) :: String.t
  def shift_date_range(iso_string, shift_value) do
    iso_string
    |> Timex.parse!("{ISOdate}")
    |> Timex.shift(months: shift_value)
    |> Timex.beginning_of_month
    |> Timex.format!("{ISOdate}")
  end

  @spec calendar_title(%{required(String.t) => String.t}) :: String.t
  def calendar_title(%{"month" => month}) do
    if valid_iso_month?(month) do
      name_of_month(month)
    else
      calendar_title(%{})
    end
  end
  def calendar_title(_missing_month) do
    "Upcoming Events"
  end

  @spec no_results_message(%{required(String.t) => String.t}) :: String.t
  def no_results_message(%{"month" => month}) do
    if valid_iso_month?(month) do
      "Sorry, there are no events in #{name_of_month(month)}."
    else
      no_results_message(%{})
    end
  end
  def no_results_message(_missing_month) do
    "Sorry, there are no upcoming events."
  end

  defp valid_iso_month?(iso_string) do
    {:ok, _date}
    |> match?(Timex.parse(iso_string, "{ISOdate}"))
  end

  defp name_of_month(iso_string) do
    iso_string
    |> Timex.parse!("{ISOdate}")
    |> Timex.format!("{Mfull}")
  end

  @doc "Nicely renders the duration of an event, given two DateTimes."
  @spec event_duration(NaiveDateTime.t | DateTime.t, NaiveDateTime.t | DateTime.t | nil) :: String.t
  def event_duration(start_time, end_time)
  def event_duration(start_time, nil) do
    start_time
    |> maybe_shift_timezone
    |> do_event_duration(nil)
  end
  def event_duration(start_time, end_time) do
    start_time
    |> maybe_shift_timezone
    |> do_event_duration(maybe_shift_timezone(end_time))
  end

  defp maybe_shift_timezone(%NaiveDateTime{} = time) do
    time
  end
  defp maybe_shift_timezone(%DateTime{} = time) do
    Util.to_local_time(time)
  end

  defp do_event_duration(start_time, nil) do
    "#{format_date(start_time)} at #{format_time(start_time)}"
  end
  defp do_event_duration(
    %{year: year, month: month, day: day} = start_time,
    %{year: year, month: month, day: day} = end_time) do
    "#{format_date(start_time)} at #{format_time(start_time)} - #{format_time(end_time)}"
  end
  defp do_event_duration(start_time, end_time) do
    "#{format_date(start_time)} #{format_time(start_time)} - #{format_date(end_time)} #{format_time(end_time)}"
  end

  defp format_time(time) do
    Timex.format!(time, "{h12}:{m}{am}")
  end

  @doc "Returns a pretty format for the event's city and state"
  @spec city_and_state(%Content.Event{}) :: String.t | nil
  def city_and_state(%Content.Event{city: city, state: state}) do
    if city && state do
      "#{city}, #{state}"
    end
  end
end

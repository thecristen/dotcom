defmodule Site.IcalendarGenerator do
  import Site.Router.Helpers

  @spec to_ical(Content.Event.t) :: String.t
  def to_ical(%Content.Event{} = event) do
    [
      "BEGIN:VCALENDAR\n",
      "VERSION:2.0\n",
      "PRODID:-//www.mbta.com//Events//EN\n",
      "BEGIN:VEVENT\n",
      "UID:", "event", "#{event.id}", "@mbta.com", "\n",
      "SEQUENCE:", timestamp(), "\n",
      "DTSTART;TZID=\"America/New_York\":", start_time(event), "\n",
      "DTEND;TZID=\"America/New_York\":", end_time(event), "\n",
      "DESCRIPTION:", description(event), "\n",
      "LOCATION:", full_address(event), "\n",
      "SUMMARY:", event.title, "\n",
      "URL:", full_url(event), "\n",
      "END:VEVENT\n",
      "END:VCALENDAR\n"
    ]
  end

  defp full_address(event) do
    [
      event.location, " ",
      event.street_address, " ",
      event.city, ", ",
      event.state
    ]
  end

  defp description(event) do
    event.body |> Phoenix.HTML.safe_to_string |> HtmlSanitizeEx.strip_tags
  end

  defp timestamp do
    Timex.now |> Timex.format!("{ISO:Basic:Z}")
  end

  defp full_url(event) do
    event_url(Site.Endpoint, :show, event.id)
  end

  defp start_time(%Content.Event{start_time: nil}), do: ""
  defp start_time(%Content.Event{start_time: start_time}) do
    start_time |> convert_to_ical_format
  end

  defp end_time(%Content.Event{end_time: nil}), do: ""
  defp end_time(%Content.Event{end_time: end_time}) do
    end_time |> convert_to_ical_format
  end

  defp convert_to_ical_format(datetime) do
    datetime
    |> Util.to_local_time
    |> Timex.format!("{YYYY}{0M}{0D}T{h24}{m}{s}")
  end
end

defmodule Content.EventPayload do
  alias Content.IsoDateTime

  @spec from_meeting(map) :: map | no_return
  def from_meeting(map) do
    map
    |> build_event()
    |> format_for_cms()
  end

  defp build_event(map) do
    %Content.Event{
      body: body(map),
      start_time: meeting_start_date_time(map),
      end_time: meeting_end_date_time(map),
      imported_address: meeting_address(map),
      meeting_id: meeting_id(map),
      title: title(map),
      who: who(map)
    }
  end

  defp format_for_cms(event) do
    %{
      body: cms_format(event.body),
      field_imported_address: cms_format(event.imported_address),
      field_meeting_id: cms_format(event.meeting_id),
      field_start_time: cms_format_start_date_time(event.start_time),
      field_end_time: cms_format_end_date_time(event.end_time),
      field_who: cms_format(event.who),
      title: cms_format(event.title),
      type: [%{"target_id": "event"}]
    }
  end

  defp title(%{"organization" => title}), do: title

  defp body(%{"objective" => body}), do: body

  defp who(%{"attendees" => attendees}), do: attendees

  defp meeting_id(%{"meeting_id" => meeting_id}), do: meeting_id

  defp meeting_address(%{"location" => address}) do
    HtmlSanitizeEx.strip_tags(address)
  end

  defp meeting_start_date_time(%{"meetdate" => date, "meettime" => time}) do
    case IsoDateTime.parse_start_time(time) do
      {:ok, time} -> IsoDateTime.utc_date_time(date, time)
      {:error, _message} -> nil
    end
  end

  defp meeting_end_date_time(%{"meetdate" => date, "meettime" => time}) do
    case IsoDateTime.parse_end_time(time) do
      {:ok, time} -> IsoDateTime.utc_date_time(date, time)
      {:error, _message} -> nil
    end
  end

  defp cms_format_start_date_time(nil) do
    raise "Please include a start time."
  end
  defp cms_format_start_date_time(time) do
    cms_format_date_time(time)
  end

  defp cms_format_end_date_time(nil) do
    cms_format(nil)
  end
  defp cms_format_end_date_time(time) do
    cms_format_date_time(time)
  end

  defp cms_format_date_time(datetime) do
    datetime
    |> Timex.format!("{YYYY}-{0M}-{0D}T{h24}:{m}:{s}")
    |> cms_format
  end

  defp cms_format(value) do
    [%{"value": value}]
  end
end

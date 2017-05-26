defmodule Content.CmsMigration.EventPayload do
  alias Content.CmsMigration.Meeting
  alias Content.CmsMigration.DataNormalizer

  @former_mbta_host Application.get_env(:site, :former_mbta_site)[:host]

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
      body: cms_format_body(event.body),
      field_imported_address: cms_format(event.imported_address),
      field_meeting_id: cms_format(event.meeting_id),
      field_start_time: cms_format_date_time(event.start_time),
      field_end_time: cms_format_date_time(event.end_time),
      field_who: cms_format(event.who),
      title: cms_format(event.title),
      type: [%{"target_id": "event"}]
    }
  end

  defp title(%{"organization" => title}) do
    HtmlSanitizeEx.strip_tags(title)
  end

  defp body(%{"objective" => body}) do
    body
    |> DataNormalizer.update_relative_links("uploadedfiles", @former_mbta_host)
    |> DataNormalizer.update_relative_image_paths("uploadedimages", @former_mbta_host)
    |> DataNormalizer.remove_style_information()
  end

  defp who(%{"attendees" => attendees}), do: attendees

  defp meeting_id(%{"meeting_id" => meeting_id}), do: meeting_id

  defp meeting_address(%{"location" => address}) do
    HtmlSanitizeEx.strip_tags(address)
  end

  defp meeting_start_date_time(%{"meetdate" => date, "meettime" => time_range}) do
    case Meeting.start_utc_datetime(date, time_range) do
      {:error, _start_time_not_found} -> nil
      start_datetime -> start_datetime
    end
  end

  defp meeting_end_date_time(%{"meetdate" => date, "meettime" => time_range}) do
    case Meeting.end_utc_datetime(date, time_range) do
      {:error, _end_time_not_found} -> nil
      end_datetime -> end_datetime
    end
  end

  defp cms_format(value) do
    [%{"value": value}]
  end

  defp cms_format_body(value) do
    [%{"value": value, "format": "basic_html"}]
  end

  defp cms_format_date_time(nil) do
    cms_format(nil)
  end
  defp cms_format_date_time(datetime) do
    datetime
    |> Timex.format!("{YYYY}-{0M}-{0D}T{h24}:{m}:{s}")
    |> cms_format
  end
end

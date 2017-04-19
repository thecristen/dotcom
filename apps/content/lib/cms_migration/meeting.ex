defmodule Content.CmsMigration.Meeting do
  alias Content.CmsMigration.MeetingDatetime
  alias Content.CmsMigration.MeetingTimeRange

  @spec start_utc_datetime(String.t, String.t) :: DateTime.t | {:error, term}
  def start_utc_datetime(date, time_range) do
    case MeetingTimeRange.parse_start_time(time_range) do
      {:error, _message} -> {:error, :invalid_time_range}
      start_time -> MeetingDatetime.parse_utc_datetime(date, start_time)
    end
  end

  @spec end_utc_datetime(String.t, String.t) :: DateTime.t | {:error, term}
  def end_utc_datetime(date, time_range) do
    case MeetingTimeRange.parse_end_time(time_range) do
      {:error, _message} -> {:error, :invalid_time_range}
      end_time -> MeetingDatetime.parse_utc_datetime(date, end_time)
    end
  end
end

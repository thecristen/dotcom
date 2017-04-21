defmodule Content.CmsMigration.MeetingDatetimeError do
  defexception [:message]
end

defmodule Content.CmsMigration.MeetingDatetime do
  alias Content.CmsMigration.MeetingDatetimeError

  @spec parse_utc_datetime(String.t, String.t, Timex.Types.valid_timezone) :: DateTime.t
  def parse_utc_datetime(date, time, timezone \\ "America/New_York") do
    date
    |> naive_datetime_from(time)
    |> convert_to_utc(timezone)
  end

  @spec parse_time!(String.t) :: Time.t | no_return
  def parse_time!(time) do
    case parse(time, accepted_time_formats()) do
      {:error, message} -> raise MeetingDatetimeError, message: message
      naive_datetime -> NaiveDateTime.to_time(naive_datetime)
    end
  end

  @spec parse_date!(String.t) :: Date.t | no_return
  def parse_date!(date) do
    date = remove_unncessary_punctuation(date)

    case parse(date, accepted_date_formats()) do
      {:error, message} -> raise MeetingDatetimeError, message: message
      naive_datetime -> NaiveDateTime.to_date(naive_datetime)
    end
  end

  defp naive_datetime_from(date, time) do
    time = parse_time!(time)
    date = parse_date!(date)

    {:ok, naive_datetime} = NaiveDateTime.new(date, time)
    naive_datetime
  end

  defp convert_to_utc(naive_datetime, timezone) do
    naive_datetime
    |> Timex.to_datetime(timezone)
    |> Timex.Timezone.convert("Etc/UTC")
  end

  defp parse(string, [head | tail]) do
    case Timex.parse(string, head) do
      {:ok, naive_datetime} -> naive_datetime
      {:error, _message} -> parse(string, tail)
    end
  end
  defp parse(string, []) do
    {:error, "Unable to convert '#{string}' to a datetime."}
  end

  defp remove_unncessary_punctuation(string) do
    string
    |> String.replace(",", " ")
    |> String.split(" ", trim: true)
    |> Enum.join(" ")
  end

  defp accepted_date_formats do
    [
      "{Mfull} {0D} {YYYY}",
      "{0M}/{0D}/{YYYY}"
    ]
  end

  defp accepted_time_formats do
    [
      "{h12}:{0m}{AM}",
      "{h12}{0m}{AM}",
      "{h12}{AM}"
    ]
  end
end

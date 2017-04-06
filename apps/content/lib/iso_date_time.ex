defmodule Content.IsoDateTime do
  @doc """
  Returns a datetime in UTC.
  Example: IsoDateTime.utc("January 1, 2017", "2:00 PM")
  """
  @spec utc_date_time(String.t, String.t, Types.valid_timezone) :: DateTime.t | {:error, term}
  def utc_date_time(date, time, timezone \\ "America/New_York") do
    date
    |> date_time_with_timezone(time, timezone)
    |> Timex.parse!("%B %e, %Y %R %p %Z", :strftime)
    |> Timex.Timezone.convert("Etc/UTC")
  end

  @spec parse_start_time(String.t) :: String.t | {:error, term}
  def parse_start_time(time) do
    time
    |> split_time_range()
    |> capture_start_time
  end

  @spec parse_end_time(String.t) :: String.t | {:error, term}
  def parse_end_time(time) do
    time
    |> split_time_range()
    |> capture_end_time
  end

  defp date_time_with_timezone(date, time, timezone) do
    Enum.join([date, time, timezone], " ")
  end

  defp split_time_range(time) do
    maybe_start_and_end_times = Regex.split(~r{-}, time)
    Enum.map(maybe_start_and_end_times, &String.strip(&1))
  end

  defp capture_start_time([""]), do: {:error, "Expected a single time or time range."}
  defp capture_start_time([start_time]), do: {:ok, start_time}
  defp capture_start_time([start_time, _end_time]), do: {:ok, start_time}

  defp capture_end_time([_start_time, end_time]), do: {:ok, end_time}
  defp capture_end_time([_start_time]), do: {:error, "Expected a time range with an end time."}
end

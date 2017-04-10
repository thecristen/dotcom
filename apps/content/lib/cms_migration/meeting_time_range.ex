defmodule Content.CmsMigration.MeetingTimeRange do
  @spec parse_start_time(String.t) :: String.t | {:error, term}
  def parse_start_time(time_range) do
    time_range
    |> standardize_format()
    |> String.split("-")
    |> capture_start_time()
  end

  @spec parse_end_time(String.t) :: String.t | {:error, term}
  def parse_end_time(time_range) do
    time_range
    |> standardize_format()
    |> String.split("-")
    |> capture_end_time()
  end

  @spec standardize_format(String.t) :: String.t | {:error, term}
  def standardize_format(time_range) do
    time_range
    |> remove_unncessary_punctuation()
    |> String.split("-")
    |> verify_format()
  end

  defp remove_unncessary_punctuation(time_range) do
    time_range
    |> String.trim()
    |> String.upcase()
    |> String.replace(",", "")
    |> String.replace(".", "")
    |> String.replace("\u2013", "-")
    |> String.replace("TO", "-")
    |> String.replace(" ", "")
  end

  defp verify_format([start_time]) do
    start_time
  end
  defp verify_format([start_time, end_time]) do
    maybe_add_missing_am_pm_value(start_time, end_time)
  end
  defp verify_format(unknown_format) do
    {:error, "Unable to standardize time range: #{unknown_format}."}
  end

  defp maybe_add_missing_am_pm_value(start_time, end_time) do
    start_time = case am_pm_value(start_time) do
      [_am_pm] -> start_time
      [] -> infer_am_pm_from_end_time(start_time, end_time)
    end
    Enum.join([start_time, end_time], "-")
  end

  defp am_pm_value(time) do
    Regex.scan(~r/AM|PM/, time)
  end

  defp infer_am_pm_from_end_time(start_time, end_time) do
    start_time <> "#{am_pm_value(end_time)}"
  end

  defp capture_start_time([""]), do: {:error, "Expected a single time or time range."}
  defp capture_start_time([start_time]), do: start_time
  defp capture_start_time([start_time, _end_time]), do: start_time

  defp capture_end_time([_start_time, end_time]), do: end_time
  defp capture_end_time([_start_time]), do: {:error, "Expected a time range with an end time."}
end

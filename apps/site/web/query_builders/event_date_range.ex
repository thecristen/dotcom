defmodule Site.EventDateRange do
  @spec build(%{String.t => String.t}, Date.t) :: map
  def build(%{"month" => month}, current_date) do
    case Date.from_iso8601(month) do
      {:ok, date} -> for_month(date)
      {:error, _error} -> upcoming_events_from(current_date)
    end
  end
  def build(_month_missing, current_date) do
    upcoming_events_from(current_date)
  end

  @spec for_month(Date.t) :: map
  def for_month(date) do
    start_date = date |> Timex.beginning_of_month
    end_date = date |> Timex.end_of_month

    date_range(start_date: start_date, end_date: end_date)
  end

  defp upcoming_events_from(date) do
    end_date = date |> thirty_days_out
    date_range(start_date: date, end_date: end_date)
  end

  defp thirty_days_out(date) do
    date |> Timex.shift(days: 30)
  end

  defp date_range(start_date: start_date, end_date: end_date) do
    %{
      start_time_gt: start_date |> convert_to_iso_format,
      start_time_lt: end_date |> convert_to_iso_format
    }
  end

  defp convert_to_iso_format(date) do
    date |> Timex.format!("{ISOdate}")
  end
end

defmodule Site.EventQueryBuilder do
  @number_of_days_out 30

  @spec upcoming_events(Date.t | DateTime.t) :: map
  def upcoming_events(start_date) do
    %{
      start_time_gt: iso_start_date(start_date),
      start_time_lt: iso_end_date(start_date)
    }
  end

  defp iso_start_date(start_date) do
    start_date |> convert_to_iso_format
  end

  defp iso_end_date(start_date) do
    Timex.shift(start_date, days: @number_of_days_out)
    |> convert_to_iso_format
  end

  defp convert_to_iso_format(date) do
    date |> Timex.format!("{ISOdate}")
  end
end

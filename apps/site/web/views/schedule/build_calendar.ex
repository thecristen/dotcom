defmodule Site.ScheduleView.Calendar do
  use Site.Web, :view
  alias Site.ScheduleView

  @doc "Builds the links that will be displayed on the calendar"
  @spec build_calendar(Date.t, [Holiday.t], Plug.Conn.t) :: [Phoenix.HTML.Safe.t]
  def build_calendar(date, holidays, conn) do
    first_day = date |> Timex.beginning_of_month |> Timex.weekday |> Kernel.rem(7)
    last_day = Timex.end_of_month(date).day
    do_build_calendar(first_day, last_day, 1, [], 0)
    |> Enum.reverse
    |> mark_holidays(holidays)
    |> Enum.map(&(mark_current_day(&1, date)))
    |> build_date_links(conn, date)
    |> additional_dates(conn, date)
  end

  @spec mark_current_day({String.t, integer}, Date.t) :: {String.t, integer}
  defp mark_current_day({_class, day} = full_day, date) do
    current_day = date.day
    case day do
      ^current_day -> {"schedule-today", current_day}
      _ -> full_day
    end
  end

  @spec mark_holidays([integer], [Holiday.t]) :: [{String.t, integer}]
  defp mark_holidays(days, holidays) do
    holiday_days = holidays |> Enum.map(&(&1.date.day))
    days
    |> Enum.map(fn d -> mark_holiday(d, holiday_days) end)
  end

  @spec mark_holiday(integer, [Holiday.t]) :: {String.t, integer}
  defp mark_holiday(day, holidays) do
    cond do
      day in holidays -> {"schedule-holiday", day}
      true -> {"", day}
    end
  end

  @spec do_build_calendar(integer, integer, integer, [integer], integer) :: [integer]
  defp do_build_calendar(first_day, last_day, current_day, days, count) do
    build_with_days = fn(current, days) ->
      do_build_calendar(first_day, last_day, current, days, count + 1)
    end
    cond do
      count < first_day -> build_with_days.(1, [0 | days])
      current_day <= last_day -> build_with_days.(current_day + 1, [current_day | days])
      true -> days
    end
  end

  # Fill up the remaining week and add 1 additional week
  @spec additional_dates([integer], Plug.Conn.t, Date.t) :: [Phoenix.HTML.Safe.t]
  defp additional_dates(days, conn, date) do
    links_needed = min((7 - rem(Enum.count(days), 7)) + 7, 13)
    additional = 1..links_needed
                 |> Enum.map(fn d -> {"schedule-next-month", d} end)
                 |> build_date_links(conn, ScheduleView.add_month(date))
    Enum.concat(days, additional)
  end

  @spec date_link({String.t, integer}, Plug.Conn.t, Date.t) :: Phoenix.HTML.Safe.t
  defp date_link({_class, 0}, _conn, _date) do
    content_tag :td do
      content_tag(:span, "")
    end
  end
  defp date_link({class, day}, conn, date) do
    formatted_date = Timex.format!({date.year,date.month, day}, "%Y-%m-%d", :strftime)
    content_tag :td, class: class do
      link(day, to: ScheduleView.update_schedule_url(conn, date: formatted_date, date_select: false))
    end
  end

  @spec build_date_links(Enum.t, Plug.Conn.t, Date.t) :: [Phoenix.HTML.Safe.t]
  defp build_date_links(days, conn, date) do
    Enum.map(days, &(date_link(&1, conn, date)))
  end
end

defmodule Site.ScheduleV2.DatePicker do
  use Plug.Builder
  alias Plug.Conn
  import Site.ScheduleV2View, only: [update_schedule_url: 2]

  plug :assign_date_select
  plug :build_calendar

  @spec assign_date_select(Conn.t, []) :: Conn.t
  def assign_date_select(conn, []) do
    assign(conn, :date_select, show_datepicker?(conn))
  end

  @doc "If the date selector is open, build the calendar"
  @spec build_calendar(Conn.t, []) :: Conn.t
  def build_calendar(%Conn{assigns: %{date_select: false}} = conn, []) do
    conn
  end
  def build_calendar(%Conn{assigns: %{date: date}} = conn, []) do
    holidays = Holiday.Repo.holidays_in_month(date)
    calendar = BuildCalendar.build(date, holidays, &update_schedule_url(conn, &1))

    conn
    |> assign(:holidays, holidays)
    |> assign(:calendar, calendar)
  end

  @spec show_datepicker?(Conn.t) :: boolean
  defp show_datepicker?(%Conn{query_params: %{"date_select" => "true"}}), do: true
  defp show_datepicker?(%Conn{}), do: false
end

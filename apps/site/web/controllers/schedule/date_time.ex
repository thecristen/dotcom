defmodule Site.ScheduleController.DateTime do
  @moduledoc "Assign @datetime, a relevant time to use for filtering alerts"

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(conn, []) do
    conn
    |> assign(:datetime, datetime(conn))
  end

  def datetime(%{assigns: %{trip_schedule: [schedule|_]}}) do
    schedule.time
  end
  def datetime(%{assigns: %{date: date}}) do
    if Timex.equal?(Util.service_date(), date) do
      Util.now()
    else
      # noon
      date
      |> Timex.to_datetime("America/New_York")
      |> Timex.set(hour: 12)
    end
  end
end

defmodule Site.ScheduleV2Controller.LineNextThreeHolidays do

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{date: date}} = conn, _opts) do
    holidays = date
    |> Holiday.Repo.following
    |> Enum.take(3)

    conn
    |> assign(:holidays, holidays)
  end
  def call(conn, _opts) do
    conn
  end

end

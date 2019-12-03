defmodule SiteWeb.ScheduleController.Holidays do
  @behaviour Plug
  import Plug.Conn, only: [assign: 3]
  alias SiteWeb.ViewHelpers

  @impl true
  def init(opts) do
    opts
  end

  @impl true
  def call(%Plug.Conn{assigns: %{date: date}} = conn, _opts) do
    holidays =
      date
      |> Holiday.Repo.following()
      |> Enum.map(fn holiday ->
        Map.put_new(holiday, :formatted_date, ViewHelpers.format_full_date(holiday.date))
      end)

    conn
    |> assign(:holidays, holidays)
  end

  def call(conn, _opts) do
    conn
  end
end

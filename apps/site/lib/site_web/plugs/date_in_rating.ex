defmodule SiteWeb.Plugs.DateInRating do
  @moduledoc """
  Plug to validate the given date as being in the current schedule rating.

  If the date is outside the current rating, then we redirect such that the
  date isn't in the URL anymore.
  """
  @behaviour Plug
  import Phoenix.Controller, only: [redirect: 2]
  alias Plug.Conn

  @impl Plug
  def init([]), do: [dates_fn: &Schedules.Repo.rating_dates/0]

  @impl Plug
  def call(%Conn{assigns: %{date: date}, query_params: %{"date" => _}} = conn, [dates_fn: dates_fn]) do
    case dates_fn.() do
      {start_date, end_date} ->
        if Date.compare(start_date, date) != :gt and
        Date.compare(end_date, date) != :lt do
          conn
        else
          url = UrlHelpers.update_url(conn, date: nil)
          conn
          |> redirect(to: url)
          |> Conn.halt
        end
      :error ->
        conn
    end
  end
  def call(%Conn{} = conn, _) do
    conn
  end
end

defmodule Site.Plugs.Holidays do
  @moduledoc """

  Assigns @holidays based on a `date` parameter in the conn.

  """
  import Plug.Conn, only: [assign: 3, halt: 1]

  def init([]), do: %{}

  def call(%{assigns: %{date: date}} = conn, _params) do
    conn
    |> assign(:holidays, Holiday.Repo.holidays_in_month(date))
  end
  def call(conn, _params) do
    conn
    |> halt # Ensure this plug is called after date has been set
  end
end

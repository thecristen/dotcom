defmodule Site.Plugs.Date do
  @moduledoc """

  Assigns @date to the Conn based on the "date" param.  If the date param is
  invalid or missing, uses today's service date.

  """
  @behaviour Plug
  import Plug.Conn, only: [assign: 3]

  @impl true
  def init([]), do: [date_fn: &Util.service_date/0]

  @impl true
  def call(conn, [date_fn: date_fn]) do
    conn
    |> assign(:date, date(conn.params["date"], date_fn))
  end

  defp date(nil, date_fn) do
    date_fn.()
  end
  defp date(str, date_fn) when is_binary(str) do
    case Timex.parse(str, "{ISOdate}") do
      {:ok, value} -> Timex.to_date(value)
      _ -> date_fn.()
    end
  end
end

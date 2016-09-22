defmodule Site.Plugs.Date do
  @moduledoc """

  Assigns @date to the Conn based on the "date" param.  If the date param is
  invalid or missing, uses today's date.

  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(conn, []) do
    conn
    |> assign(:date, date(conn.params["date"]))
  end

  defp date(nil) do
    Util.today
  end
  defp date(str) when is_binary(str) do
    case Timex.parse(str, "{ISOdate}") do
      {:ok, value} -> Timex.to_date(value)
      _ -> Util.today
    end
  end
end

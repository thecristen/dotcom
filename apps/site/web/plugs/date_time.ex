defmodule Site.Plugs.DateTime do
  @moduledoc """

  Assigns @date to the Conn based on the "date" param.  If the date param is
  invalid or missing, uses today's service date.

  """
  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(conn, []) do
    conn
    |> assign(:date_time, date_time(conn.params["date_time"]))
  end

  defp date_time(nil) do
    Util.now()
  end
  defp date_time(str) when is_binary(str) do
    case Timex.parse(str, "{ISO:Extended}") do
      {:ok, value} -> Timex.to_datetime(value, "America/New_York")
      _ -> Util.now()
    end
  end
end

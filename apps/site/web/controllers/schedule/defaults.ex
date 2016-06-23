defmodule Site.ScheduleController.Defaults do
  import Plug.Conn
  use Timex

  @doc """
  For a given %Plug.Conn, assign some default values based on the query
  parameters.
  """
  def default_assigns(conn) do
    conn.params
    |> index_params
    |> Enum.reduce(conn, fn {key, value}, conn -> assign(conn, key, value) end)
  end

  defp index_params(params) do
    date = default_date(params)

    direction_id = default_direction_id(params)

    show_all = params["all"] != nil || not Timex.equal?(Date.today, date)

    [
      date: date,
      show_all: show_all,
      direction_id: direction_id,
      reverse_direction_id: reverse_direction_id(direction_id),
      origin: params["origin"],
      destination: params["dest"],
    ]
  end

  defp default_date(params) do
    case Timex.parse(params["date"], "{ISOdate}") do
      {:ok, value} -> value |> Date.from
      _ -> Date.today
    end
  end

  defp default_direction_id(params) do
    case params["direction_id"] do
      nil ->
        if DateTime.now("America/New_York").hour <= 13 do
          1 # Inbound
        else
          0
        end

      str ->
        String.to_integer(str)
    end
  end

  defp reverse_direction_id(0), do: 1
  defp reverse_direction_id(1), do: 0
  defp reverse_direction_id(_), do: 1 # Unknown, so pick a default
end

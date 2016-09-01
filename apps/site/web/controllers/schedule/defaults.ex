defmodule Site.ScheduleController.Defaults do
  import Plug.Conn
  use Timex

  import Util

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

    show_all = params["all"] != nil || not Timex.equal?(today, date)

    [
      date: date,
      show_all: show_all,
      direction_id: direction_id,
      reverse_direction_id: reverse_direction_id(direction_id),
      origin: case params["origin"] do
                "" -> nil
                value -> value
              end,
      destination: case params["dest"] do
                     "" -> nil
                     value -> value
                   end,
    ]
  end

  defp default_date(params) do
    case Timex.parse(params["date"], "{ISOdate}") do
      {:ok, value} -> value |> Timex.to_date
      _ -> today
    end
  end

  defp default_direction_id(%{"direction_id" => direction_str}) when is_binary(direction_str) do
    case Integer.parse(direction_str) do
      {0, _} -> 0
      {1, _} -> 1
      _ -> default_direction_id(nil) # fallback to the default
    end
  end
  defp default_direction_id(_) do
    if Util.now.hour <= 13 do
      1 # Inbound
    else
      0
    end
  end

  def reverse_direction_id(0), do: 1
  def reverse_direction_id(1), do: 0
  def reverse_direction_id(_), do: 1 # Unknown, so pick a default
end

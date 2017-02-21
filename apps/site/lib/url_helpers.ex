defmodule UrlHelpers do

  @spec update_url(Plug.Conn.t, Enum.t) :: String.t
  def update_url(conn, query) do
    conn
    |> update_query(query)
    |> do_update_url(conn)
  end

  @spec do_update_url(map, Plug.Conn.t) :: String.t
  defp do_update_url(updated, conn) when updated == %{} do
    conn.request_path
  end
  defp do_update_url(updated, conn) do
    "#{conn.request_path}?#{URI.encode_query(updated)}"
  end

  def update_query(%{query_params: params}, query) do
    params = params || %{}
    query_map = query
    |> Map.new(fn {key, value} -> {to_string(key), value} end)

    params
    |> Map.merge(query_map)
    |> Enum.reject(&empty_value?/1)
    |> Map.new
  end

  defp empty_value?({_, nil}), do: true
  defp empty_value?({_, _}), do: false
end

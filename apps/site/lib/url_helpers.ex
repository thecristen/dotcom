defmodule UrlHelpers do
  @spec update_url(Plug.Conn.t, Enum.t) :: String.t
  def update_url(conn, query) do
    conn.query_params
    |> update_query(query)
    |> do_update_url(conn)
  end

  @spec do_update_url(map, Plug.Conn.t) :: String.t
  defp do_update_url(updated, conn) when updated == %{} do
    conn.request_path
  end
  defp do_update_url(updated, conn) do
    "#{conn.request_path}?#{Plug.Conn.Query.encode(updated)}"
  end

  @doc """
  Updates a query parameter map with new values.

  If `nil` is passed as a value, that key is removed from the output.
  """
  @spec update_query(map, Enumerable.t) :: map
  def update_query(%{} = old_params, new_params) do
    new_params = ensure_string_keys(new_params)

    old_params
    |> Map.merge(new_params, &update_query_merge/3)
    |> Enum.reject(&empty_value?/1)
    |> Map.new
  end

  defp ensure_string_keys(map) do
    for {key, value} <- map, into: %{} do
      {to_string(key), value}
    end
  end

  defp update_query_merge(_key, old_value, new_value) when is_map(new_value) do
    new_value = ensure_string_keys(new_value)
    Map.merge(old_value, new_value, &update_query_merge/3)
  end
  defp update_query_merge(_key, _old_value, new_value) do
    new_value
  end

  defp empty_value?({_, nil}), do: true
  defp empty_value?({_, _}), do: false
end

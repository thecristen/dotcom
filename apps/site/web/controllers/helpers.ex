defmodule Site.ControllerHelpers do

  @doc "Find all the assigns which are Tasks, and await_assign them"
  def await_assign_all(conn) do
    conn.assigns
    |> Enum.filter_map(
    fn
      {_, %Task{}} -> true
      _ -> false
    end,
    fn {key, _} -> key end)
    |> Enum.reduce(conn, fn key, conn -> Plug.Conn.await_assign(conn, key) end)
  end
end

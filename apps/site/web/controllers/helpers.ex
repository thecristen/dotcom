defmodule Site.ControllerHelpers do
  import Plug.Conn, only: [assign: 3]
  alias Plug.Conn
  alias Stops.Stop
  alias Routes.Route

  @doc "Find all the assigns which are Tasks, and await_assign them"
  def await_assign_all(conn) do
    conn.assigns
    |> Enum.filter_map(
    fn
      {_, %Task{}} -> true
      _ -> false
    end,
    fn {key, _} -> key end)
    |> Enum.reduce(conn, fn key, conn -> Conn.await_assign(conn, key) end)
  end

  @spec assign_tnm_column_groups(Conn.t) :: Conn.t
  def assign_tnm_column_groups(%Conn{params: %{"location" => %{"client_width" => "0"}}} = conn) do
    conn
    |> assign(:stop_groups, nil)
  end
  def assign_tnm_column_groups(%Conn{assigns: %{stops_with_routes: stops}, params: %{"location" => %{"client_width" => client_width}}} = conn) do
    client_width
    |> String.to_integer
    |> get_group_number
    |> make_tnm_column_groups(stops)
    |> do_assign_tnm_column_groups(conn)
  end
  def assign_tnm_column_groups(conn) do
    conn
    |> assign(:stop_groups, nil)
  end

  defmacro call_plug(conn, module) do
    opts = Macro.expand(module, __ENV__).init([])
    quote do
      unquote(module).call(unquote(conn), unquote(opts))
    end
  end

  @spec do_assign_tnm_column_groups(%{integer => [%{stop: Stop.t, distance: float, routes: [Route.t]}]}, Conn.t) :: Conn.t
  defp do_assign_tnm_column_groups(grouped_stops, conn) do
    assign(conn, :stop_groups, grouped_stops)
  end

  @spec make_tnm_column_groups(integer, [Stop.t]) :: %{integer => [%{stop: Stop.t, distance: float, routes: [Route.t]}]}
  defp make_tnm_column_groups(number_of_groups, stops) do
    stops
    |> Enum.with_index
    |> Enum.group_by(fn {_stop, idx} -> rem(idx, number_of_groups) end, fn {stop, _idx} -> stop end)
  end

  @spec get_group_number(integer) :: integer
  defp get_group_number(width) when width >= 960, do: 4
  defp get_group_number(width) when width >= 768, do: 3
  defp get_group_number(width) when width >= 543, do: 2
  defp get_group_number(_), do: 1
end

defmodule Util.AsyncAssign do
  @moduledoc """
  Utility for assigning in `Conn` asynchronously and setting defaults if the
  task times out.

  The functions in this module allow setting certain keys in `:assigns`
  asynchronously in a plug or controller with a defined fall-through behavior
  in the case of a time out or error.
  """

  alias Plug.Conn

  @doc """
  Starts a task to assign a value to a key in the connection and saves a default
  value.

  When `await_assign/2` is called, it will wait until the task completes and put
  that value under `key` in the `:assigns` field. If the task times out, then it
  will use `default`.

  The implementation is based on `Plug.Conn.async_assign/3`:
  https://github.com/elixir-plug/plug/blob/3d48af2b97d58c183a7b8390abc42ac5367b0770/lib/plug/conn.ex#L309
  """
  @spec async_assign_default(Conn.t, atom, (() -> term), term) :: Conn.t
  def async_assign_default(%Conn{} = conn, key, async_fn, default \\ nil)
  when is_atom(key) and is_function(async_fn, 0) do
    Conn.assign(conn, key, {Task.async(async_fn), default})
  end

  @doc """
  For all assigns that are Tasks with defaults, call await_assign/3.

  Returns a new `Conn` with all of the async keys in `:assigns` resolved.
  """
  @spec await_assign_all_default(Conn.t, timeout) :: Conn.t
  def await_assign_all_default(conn, timeout \\ 5000) do
    task_keys = for {key, {%Task{}, _}} <- conn.assigns do
      key
    end
    Enum.reduce(task_keys, conn, fn key, conn -> await_assign(conn, key, timeout) end)
  end

  # Awaits the completion of an async assign with a default.
  #
  # Returns conn with either the async assignment or, if that times
  # out, the default, under `key` in the `:assigns` field.
  #
  # The implementation is based on `Plug.Conn.await_assign/3`:
  # https://github.com/elixir-plug/plug/blob/3d48af2b97d58c183a7b8390abc42ac5367b0770/lib/plug/conn.ex#L332
  @spec await_assign(Conn.t, atom, timeout) :: Conn.t
  defp await_assign(%Conn{} = conn, key, timeout) when is_atom(key) do
    {task, default} = Map.fetch!(conn.assigns, key)

    value = case await(task, timeout) do
      {:ok, result} -> result
      _ -> default
    end

    Conn.assign(conn, key, value)
  end

  # Awaits a task reply and returns it. If it times out first, then return an
  # error.
  #
  # The return value is either `{:ok, value}` when it does not time and and
  # `:error` when it does time out.
  #
  # The implementation is based on `Task.await/2`:
  # https://github.com/elixir-lang/elixir/blob/05418eaa4bf4fa8473900741252d93d76ed3307b/lib/elixir/lib/task.ex#L475
  @spec await(Task.t, timeout) :: {:ok, term} | :error
  defp await(%Task{owner: owner}, _) when owner != self() do
    :error
  end
  defp await(%Task{ref: ref}, timeout) do
    receive do
      {^ref, reply} ->
        Process.demonitor(ref, [:flush])
        {:ok, reply}
      {:DOWN, ^ref, _, _, _} ->
        :error
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        :error
    end
  end
end


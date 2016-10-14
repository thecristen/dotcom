defmodule Mix.Tasks.Backstop.Tests do
  use Mix.Task

  require Logger

  @shortdoc "Run Backstop tests."
  @moduledoc """
  Run Wiremock and the Phoenix server in the background, then run the Backstop tests and report their result.
  """

  def run(_args) do
    {:ok, _started} = Application.ensure_all_started(:porcelain)
    pid = self()
    phoenix_pid = spawn_link(Backstop.Servers.Phoenix, :run, [pid])
    _ = Logger.info "Phoenix started with pid #{inspect phoenix_pid}"
    wiremock_pid = spawn_link(Backstop.Servers.Wiremock, :run, [pid])
    _ = Logger.info "Wiremock started with pid #{inspect wiremock_pid}"
    loop({phoenix_pid, :not_started}, {wiremock_pid, :not_started})
  end

  def loop({phoenix_pid, :started}, {wiremock_pid, :started}) do
    try do
      _ = Logger.info "starting Backstop"
      {_stream, status} = System.cmd "npm", ["run", "backstop:test"], into: IO.stream(:stdio, :line)
      shutdown_all(phoenix_pid, wiremock_pid, status)
    rescue
      RuntimeError ->
        _ = Logger.error "Backstop did not start; shutting down"
        shutdown_all(phoenix_pid, wiremock_pid, 1)
    end
  end
  def loop({phoenix_pid, phoenix_status}, {wiremock_pid, wiremock_status}) do
    receive do
      {^phoenix_pid, :started} ->
        _ = Logger.info "started Phoenix"
        loop({phoenix_pid, :started}, {wiremock_pid, wiremock_status})
      {^wiremock_pid, :started} ->
        _ = Logger.info "started Wiremock"
        loop({phoenix_pid, phoenix_status}, {wiremock_pid, :started})
      {^phoenix_pid, :error} ->
        _ = Logger.error "error starting Phoenix"
        shutdown_all(phoenix_pid, wiremock_pid, 1)
      {^wiremock_pid, :error} ->
        _ = Logger.error "error starting Wiremock"
        shutdown_all(phoenix_pid, wiremock_pid, 1)
    after
      60_000 -> # 1 minute timeout
        _ = Logger.error "timed out waiting for servers; shutting down"
        shutdown_all(phoenix_pid, wiremock_pid, 1)
    end
  end

  def shutdown(pid) do
    if Process.alive? pid do
      send pid, {self(), :shutdown}
      receive do
        {^pid, :finished} -> nil # wait for the process to acknowledge exit
      end
    end
    _ = Logger.info "#{inspect pid} finished"
  end

  @spec shutdown_all(pid, pid, non_neg_integer) :: no_return
  def shutdown_all(phoenix_pid, wiremock_pid, status) do
    :ok = shutdown(phoenix_pid)
    :ok = shutdown(wiremock_pid)
    _ = Logger.flush
    System.halt status
  end
end

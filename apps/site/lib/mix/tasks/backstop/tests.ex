defmodule Mix.Tasks.Backstop.Tests do
  use Mix.Task

  require Logger
  import Backstop.Servers
  alias Backstop.Servers.{Wiremock, Phoenix}

  @shortdoc "Run Backstop tests."
  @moduledoc """
  Run Wiremock and the Phoenix server in the background, then run the Backstop tests and report their result.
  """

  def run(_args) do
    {:ok, wiremock_pid} = Wiremock.start_link
    _ = Logger.info "Wiremock started with pid #{inspect wiremock_pid}"

    {:ok, phoenix_pid} = Phoenix.start_link
    _ = Logger.info "Phoenix started with pid #{inspect phoenix_pid}"

    pids = [wiremock_pid, phoenix_pid]
    case Enum.map(pids, &await/1) do
      [:started, :started] ->
        run_backstop(pids)
      _ ->
        shutdown_all(pids, 1)
    end
  end

  defp run_backstop(pids) do
    status = try do
               _ = Logger.info "starting Backstop"
               {_stream, status} = System.cmd "npm", ["run", "backstop:test"], into: IO.stream(:stdio, :line)
               status
             rescue
               RuntimeError ->
                 _ = Logger.error "Backstop did not start; shutting down"
                 1
             end
    shutdown_all(pids, status)
  end

  @spec shutdown_all([pid], non_neg_integer) :: no_return
  def shutdown_all(pids, status) do
    Enum.each(pids, &shutdown/1)
    _ = Logger.flush
    System.halt status
  end
end

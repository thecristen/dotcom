defmodule Mix.Tasks.Backstop.Tests do
  use Mix.Task

  require Logger
  alias Backstop.Servers.{Wiremock, Phoenix, Helpers}

  @shortdoc "Run Backstop tests."
  @moduledoc """
  Run Wiremock and the Phoenix server in the background, then run the Backstop tests and report their result.
  """

  def run(_args) do
    [Wiremock, Phoenix]
    |> Enum.map(fn module ->
      {:ok, pid} = module.start_link
      pid
    end)
    |> Helpers.run_with_pids(&run_backstop/0)
    |> System.halt
  end

  defp run_backstop() do
    try do
      _ = Logger.info "starting Backstop"
      {_stream, status} = System.cmd "npm", ["run", "backstop:test"], into: IO.stream(:stdio, :line)
      status
    rescue
      RuntimeError ->
        _ = Logger.error "Backstop did not start; shutting down"
      1
    end
  end
end

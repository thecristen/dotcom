defmodule Mix.Tasks.Backstop.Tests do
  use Mix.Task

  require Logger
  alias Backstop.Servers.{Wiremock, Phoenix, Helpers}

  @shortdoc "Run Backstop tests."
  @moduledoc """
  Run Wiremock and the Phoenix server in the background, then run the Backstop tests and report their result.

  You can pass `--filter="<<scenario.label>>"` to only run a specific scenario instead of running the full suite.
  """

  @spec run([String.t]) :: no_return
  def run(args) do
    args
    |> Enum.map(&arg_to_tuple/1)
    |> Enum.into(%{})
    |> IO.inspect()
    |> do_run()
  end

  def do_run(args_map) do
    [Wiremock, Phoenix]
    |> Enum.map(fn module ->
      {:ok, pid} = module.start_link()
      pid
    end)
    |> Helpers.run_with_pids(args_map, &run_backstop/1)
    |> System.halt
  end

  defp run_backstop(args_map) do
    backstop_args = case args_map do
      %{"--filter" => scenario} -> ["--filter=#{scenario}"]
      _ -> []
    end
    try do
      _ = Logger.info "starting Backstop with args: #{inspect backstop_args}"
      :ok = File.cd("apps/site")
      {_stream, status} = System.cmd "backstop", ["test" | backstop_args], into: IO.stream(:stdio, :line)
      status
    rescue
      RuntimeError ->
        _ = Logger.error "Backstop did not start; shutting down"
      1
    end
  end

  defp arg_to_tuple(arg) when is_binary(arg) do
    arg
    |> String.split("=")
    |> do_arg_to_tuple()
  end

  defp do_arg_to_tuple([key]), do: {key, ""}
  defp do_arg_to_tuple([key, val]), do: {key, val}
end

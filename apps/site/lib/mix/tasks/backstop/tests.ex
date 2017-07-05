defmodule Mix.Tasks.Backstop.Tests do
  use Mix.Task

  require Logger
  alias Backstop.Servers.{Wiremock, Phoenix, Helpers}

  @shortdoc "Run Backstop tests."
  @moduledoc """
  Run Wiremock and the Phoenix server in the background, then run the Backstop tests and report their result.

  You can pass `--filter="<<scenario.label>>"` to only run a specific scenario instead of running the full suite.
  """

  @type runner_fn :: ((%{String.t => String.t}) -> non_neg_integer)

  @runner_fn &__MODULE__.run_backstop/1
  @await_fn &Backstop.Servers.await/1

  @spec run([String.t], [atom], runner_fn, Backstop.Servers.await_fn) :: no_return
  def run(args, modules \\ [Wiremock, Phoenix], runner_fn \\ @runner_fn, await_fn \\ @await_fn) do
    args
    |> Enum.map(&arg_to_tuple/1)
    |> Enum.into(%{})
    |> do_run(modules, runner_fn, await_fn)
  end

  @spec do_run(%{optional(String.t) => String.t}, [atom], runner_fn, Backstop.Servers.await_fn) :: no_return
  def do_run(args_map, modules, runner_fn, await_fn) do
    modules
    |> Enum.map(&start_server/1)
    |> Helpers.run_with_pids(args_map, runner_fn, await_fn)
    |> shutdown()
  end

  defp shutdown({status, pids}) do
    Enum.each(pids, &Backstop.Servers.shutdown/1)
    _ = Logger.flush
    return_status({status, pids})
  end

  defp return_status({0, pids}) do
    {:ok, pids}
  end
  defp return_status(error) do
    {:error, error}
  end

  @spec start_server(atom) :: pid
  def start_server(module) do
    {:ok, pid} = module.start_link()
    pid
  end

  @spec run_backstop(%{String.t => String.t}) :: non_neg_integer
  def run_backstop(args_map) do
    default_args = ["--config=apps/site/backstop.json"]
    backstop_args = case args_map do
      %{"--filter" => scenario} -> ["--filter=#{scenario}" | default_args]
      _ -> default_args
    end
    try do
      _ = Logger.info "starting Backstop with args: #{inspect backstop_args}"
      bin_path = Path.join(File.cwd!(), "apps/site/node_modules/.bin/backstop")
      {_stream, status} = System.cmd bin_path, ["test" | backstop_args], into: IO.stream(:stdio, :line)
      status
    rescue
      RuntimeError ->
        _ = Logger.error "Backstop did not start; shutting down"
      1
    end
  end

  @spec arg_to_tuple(String.t) :: {String.t, String.t}
  defp arg_to_tuple(arg) when is_binary(arg) do
    arg
    |> String.split("=")
    |> do_arg_to_tuple()
  end

  @spec do_arg_to_tuple([String.t]) :: {String.t, String.t}
  defp do_arg_to_tuple([key]), do: {key, ""}
  defp do_arg_to_tuple([key, val]), do: {key, val}
end

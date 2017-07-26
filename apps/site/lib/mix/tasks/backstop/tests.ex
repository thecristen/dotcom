defmodule Mix.Tasks.Backstop.Tests do
  use Mix.Task
  use GenServer

  require Logger
  alias Backstop.Servers.{Wiremock, Phoenix}

  @shortdoc "Run Backstop tests."
  @moduledoc """
  Run Wiremock and the Phoenix server in the background, then run the Backstop tests and report their result.

  Available run options:
      -f <<scenario.label>>,
        [--filter <<scenario.label>>]   --   run a single scenario instead of the whole suite
      --backstop-debug                  --   set Backstop's config to `debug: true`
      --run-brunch                      --   run `npm run brunch:build` before starting backstop
      -v, [--verbose]                   --   show logs from Wiremock and Phoenix. Casper logs are always displayed.
      -d, [--dev]                       --   run in dev mode: skip compilation and use localhost:4001 as server
                                                faster to run, but not a definitive test. Be sure to run without this
                                                flag at least once before merging to master.

  You can pass `--filter="<<scenario.label>>"` to only run a specific scenario instead of running the full suite.
  """

  @type arg_map :: %{atom => String.t}
  @type exit_code :: 0 | 1
  @type proc_result :: {:ok, map} | {:error, String.t | {:process_down, pid}} | :timeout
  @type runner_fn :: ((%{atom => String.t | boolean}) -> exit_code)
  @type cmd_fn :: (({String.t, map}, String.t, [String.t], Keyword.t) -> exit_code)

  @runner_fn &__MODULE__.run_backstop/3
  @cmd_fn &__MODULE__.do_try_proc/4

  @spec run([String.t], [atom], runner_fn, cmd_fn) :: no_return
  def run(args, modules \\ [Wiremock, Phoenix], runner_fn \\ @runner_fn, cmd_fn \\ @cmd_fn, timeout \\ 600_000) do
    Application.ensure_all_started(:httpoison)
    {parsed_args, []} = OptionParser.parse!(args, aliases: [v: :verbose, f: :filter, d: :dev])
    arg_map = Enum.into(parsed_args, %{})

    :ok = run_brunch(arg_map)

    state = %{args: arg_map,
              pids: modules |> Enum.map(fn mod -> {mod, {nil, :not_started}} end) |> Enum.into(%{}),
              parent: self(),
              modules: modules,
              status: :not_started,
              runner_fn: runner_fn,
              cmd_fn: cmd_fn}

    Process.flag(:trap_exit, true)
    {:ok, pid} = GenServer.start_link(__MODULE__, state)
    for module <- modules, do: GenServer.cast(pid, {:start_server, module})
    await_result(pid, timeout)
  end

  @spec run_brunch(%{atom => String.t | boolean}) :: :ok
  defp run_brunch(%{run_brunch: true}) do
    {_, 0} = System.cmd("npm", ["run", "brunch:build"], into: IO.stream(:stdio, :line))
    :ok
  end
  defp run_brunch(_), do: :ok

  @spec await_result(pid, non_neg_integer) :: {:ok, map, [{atom, pid}]} | {:error, any, [{atom, pid}]}
  def await_result(pid, timeout) do
    start = DateTime.utc_now()
    receive do
      {:test_url, url} ->
        GenServer.cast(pid, {:test_url, url})
        await_result(pid, update_timeout(timeout, start))
      {:status, [:ready]} ->
        GenServer.cast(pid, :run)
        await_result(pid, update_timeout(timeout, start))
      {:status, _} ->
        await_result(pid, update_timeout(timeout, start))
      result ->
        shutdown(pid, result, timeout)
    after
      timeout
      |> div(1000)
      |> :timer.seconds() ->
        Logger.error "Backstop timed out; shutting down servers..."
        shutdown(pid, :timeout, timeout)
    end
  end

  defp update_timeout(original, start_time) do
    diff = Timex.Comparable.diff(DateTime.utc_now(), start_time, :milliseconds)
    original - diff
  end

  @spec shutdown(pid, proc_result | :timeout, non_neg_integer)
  :: {:ok, map, [{atom, pid}]} | {:error, any, [{atom, pid}]}
  defp shutdown(pid, result, timeout) do
    if Process.alive?(pid) do
      pid
      |> GenServer.call(:pids, timeout * 1000)
      |> Enum.map(&shutdown_server/1)
      |> do_shutdown(result)
    end
  end

  @spec shutdown_server({atom, {pid, atom}}) :: {atom, pid}
  defp shutdown_server({module, {pid, _status}}) when not is_nil(pid) do
    if Process.alive?(pid) do
      GenServer.stop(pid)
    else
      Logger.info("#{module} (#{inspect(pid)}) already down; skipping")
    end
    {module, pid}
  end

  @spec do_shutdown([{pid, atom}], proc_result | :timeout) :: {:ok, map, [{pid, atom}]} | {:error, any, [{pid, atom}]}
  defp do_shutdown(pids, {:ok, result}) do
    _ = Logger.flush()
    {:ok, result, pids}
  end
    defp do_shutdown(pids, {:error, error}) do
    _ = Logger.flush()
    error
    |> inspect()
    |> Logger.error()
    {:error, error, pids}
  end
  defp do_shutdown(pids, :timeout) do
    _ = Logger.flush()
    {:error, :timeout, pids}
  end

  def handle_cast({:start_server, module}, state) do
    {_module, pid} = module.start_link(state.args)
    {:noreply, update_pid(state, module, {pid, :starting})}
  end
  def handle_cast(:run, state) do
    state.runner_fn.(state.args, state.parent, state.cmd_fn)
    {:noreply, %{state | status: :running}}
  end
  def handle_cast({:test_url, url}, state) do
    case state.pids[Backstop.Phoenix] do
      nil -> :ok
      {phoenix_pid, :ready} when is_pid(phoenix_pid) ->
        result = GenServer.call(phoenix_pid, {:test_url, url})
        send state.parent, result
    end
    {:noreply, state}
  end

  def handle_call(:build_config, state) do
    {:reply, state.pids, state}
  end
  def handle_call(:pids, _from, state) do
    {:reply, state.pids, state}
  end

  def handle_info({:DOWN, _ref, :process, down_pid, :normal}, state) do
    state = case Enum.find(state.pids, fn {_name, {pid, _status}} -> pid == down_pid end) do
      {module, {_pid, _status}} -> update_pid(state, module, {down_pid, :down})
      nil -> state
    end
    {:noreply, state}
  end
  def handle_info({module, pid, {:error, error}}, state) do
    # when the task exits unexpectedly, it sometimes leaves ghost processes running. If we get an error message that
    # the address is already in use, this will go through and find that process and kill it, then start a new
    # GenServer for that process.
    case error |> String.downcase() |> Kernel.=~("address already in use") do
      true ->
        GenServer.cast(pid, {:kill, error})
        {:noreply, update_pid(state, module, {nil, :restarted})}
      false ->
        send state.parent, {{:error, error}, state.pids}
        {:stop, :normal, state}
    end
  end
  def handle_info({module, _pid, {:restart, :ok}}, state) do
    module.start_link(state.args)
    {:noreply, state}
  end
  def handle_info({module, pid, {:server_status, :ready}}, state) do
    state = update_pid(state, module, {pid, :ready})
    send_status(state)
    {:noreply, state}
  end
  def handle_info({module, pid, {:server_status, status}}, state) do
    {:noreply, update_pid(state, module, {pid, status})}
  end

  defp update_pid(%{pids: pids} = state, module, pid_state) do
    %{state | pids: Map.put(pids, module, pid_state)}
  end

  defp send_status(%{status: :running}), do: :ok
  defp send_status(%{parent: parent, pids: pids}) do
    send parent, {:status, pids
                           |> Enum.map(&proc_status/1)
                           |> Enum.uniq()}
  end

  @spec proc_status({atom, {pid, atom}}) :: boolean
  defp proc_status({_module, {_pid, status}}), do: status

  @doc """
  Runs the backstop process and returns the process's exit status code. Can take different commands to pass to the
  process runner for tests.
  """
  @spec run_backstop(arg_map, pid, (({String.t, map}, String.t, [String.t], Keyword.t) -> exit_code)) :: proc_result
  def run_backstop(args_map, parent_pid, cmd_fn) do
    args_map
    |> build_backstop_args(parent_pid)
    |> do_run_backstop(cmd_fn, parent_pid)
  end

  @spec do_run_backstop({String.t, map, [String.t]}, cmd_fn, pid) :: proc_result
  defp do_run_backstop({config_path, config, arg_list}, cmd_fn, parent_pid) when is_list(arg_list) do
    {config_path, config, arg_list}
    |> try_proc(cmd_fn)
    |> finish_backstop(config_path, parent_pid, arg_list)
  end

  @spec try_proc({String.t, map, [String.t]}, cmd_fn) :: exit_code
  def try_proc({config_path, config, arg_list}, cmd_fn) do
    _ = Logger.info "starting Backstop with args: #{inspect arg_list}"
    cmd_args = ["apps/site/node_modules/backstopjs/cli/index.js", "test" | arg_list]
    {_stream, exit_code} = cmd_fn.({config_path, config}, "node", cmd_args, [into: IO.stream(:stdio, :line)])
    exit_code
  end

  def do_try_proc({config_path, config}, cmd, cmd_args, cmd_opts) do
    :ok = config
    |> Poison.encode()
    |> write_file(config_path)

    System.cmd(cmd, cmd_args, cmd_opts)
  end

  defp write_file({:ok, config}, path), do: File.write(path, config)

  @spec finish_backstop(exit_code, String.t, pid, [String.t]) :: proc_result
  def finish_backstop(exit_code, config_path, parent, arg_list) do
    msg = %{exit_code: exit_code, args: arg_list, config: config_path}
    file_result = if File.exists?(config_path), do: File.rm(config_path), else: :ok
    result = case file_result do
      :ok -> {:ok, msg}
      {:error, error} -> {:error, Map.put(msg, :file_error, error)}
    end
    send parent, result
    result
  end

  @doc """
  Takes the arguments passed to the mix task (converted to a map), builds a temporary JSON file to be used by the
  backstop test, and returns a tuple with the path to the temporary file, and a list of arguments to be passed to
  Backstop.
  """
  @spec build_backstop_args(arg_map, pid) :: {String.t, map, [String.t]}
  def build_backstop_args(arg_map, parent) do
    arg_map
    |> build_backstop_config()
    |> ensure_scenario_testable(arg_map, parent)
    |> get_config_path()
    |> build_backstop_arg_list(arg_map)
  end

  @spec build_backstop_config(arg_map) :: %{atom => any}
  def build_backstop_config(args) do
    {:ok, "backstop.json"}
    |> config_path()
    |> File.read!()
    |> Poison.Parser.parse(keys: :atoms)
    |> update_scenario_urls(args)
    |> set_debug_mode(args)
  end

  @spec update_scenario_urls({:ok, %{atom => any}}, %{atom => String.t | boolean}) :: %{atom => any}
  def update_scenario_urls({:ok, config}, %{dev: true}) do
    %{config | scenarios: Enum.map(config.scenarios, &update_scenario_url/1)}
  end
  def update_scenario_urls({:ok, config}, _args), do: config

  def ensure_scenario_testable(config, %{filter: scenario_label}, parent) do
    case Enum.find(config.scenarios, & &1.label == scenario_label) do
      nil -> send parent, {:error, "Scenario #{scenario_label} not found!"}
      %{url: url} -> check_url(url, parent)
    end
    config
  end
  def ensure_scenario_testable(config, _args, parent) do
    for %{url: url} <- config.scenarios do
      unless url =~ "not-found", do: check_url(url, parent)
    end
    config
  end

  defp check_url(url, parent) do
    send parent, {:test_url, url}
  end

  @spec set_debug_mode(%{atom => any}, %{atom => atom | boolean}) :: %{atom => any}
  def set_debug_mode(config, %{backstop_debug: true}) do
    %{config | debug: true}
  end
  def set_debug_mode(config, _) do
    config
  end

  @spec get_config_path(%{atom => any}) :: {String.t, map}
  def get_config_path(config) when is_map(config) do
    path = DateTime.utc_now()
    |> Timex.format("{YYYY}{M}{D}_{h24}{m}{s}_backstop.json")
    |> config_path()
    {path, config}
  end

  @spec config_path({:ok, String.t}) :: String.t
  defp config_path({:ok, file_name}) do
    :site
    |> Application.app_dir()
    |> String.replace("_build/#{Mix.env}/lib", "apps")
    |> Path.join("test")
    |> Path.join(file_name)
  end

  @spec update_scenario_url(%{atom => any}) :: %{atom => any}
  def update_scenario_url(%{url: url} = scenario) do
    port = System.get_env()
    |> Map.get("PORT", "4001")
    |> String.to_integer()

    case URI.parse(url) do
      %URI{port: ^port} -> scenario
      uri -> %{scenario | url: do_update_scenario_url(port, uri)}
    end
  end

  @spec do_update_scenario_url(non_neg_integer, URI.t) :: String.t
  defp do_update_scenario_url(port, uri) do
    URI.to_string(%{uri | port: port, scheme: "http", host: "localhost"})
  end

  @spec build_backstop_arg_list({String.t, map}, %{atom => String.t | boolean}) :: {String.t, map, [String.t]}
  def build_backstop_arg_list({config_path, config}, %{filter: scenario}) do
    do_build_backstop_arg_list(["--filter=#{scenario}"], {config_path, config})
  end
  def build_backstop_arg_list({config_path, config}, _), do: do_build_backstop_arg_list([], {config_path, config})

  @spec do_build_backstop_arg_list([String.t], {String.t, map}) :: {String.t, map, [String.t]}
  defp do_build_backstop_arg_list(filter, {config_path, config}) do
    {config_path, config, ["--config=#{config_path}" | filter]}
  end
end

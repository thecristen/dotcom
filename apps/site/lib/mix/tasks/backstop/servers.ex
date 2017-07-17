defmodule Backstop.Servers do
  require Logger
  use GenServer

  @callback environment(%{String.t => String.t}) :: [{charlist, charlist}]
  @callback command(%{String.t => String.t}) :: String.t
  @callback log_color() :: atom
  @callback started_match() :: String.t
  @callback error_match() :: String.t | Regex.t
  @callback test_url(String.t) :: :ok
  @optional_callbacks environment: 1, command: 1, test_url: 1

  defmodule State do
    @type t :: %__MODULE__{
      module: atom,
      parent: pid,
      port: port,
      env: [{charlist, charlist}],
      command: String.t,
      dir: String.t,
      args: %{atom => String.t | boolean}
    }
    defstruct [:module, :parent, :port, :env, :command, :dir, :args]
  end

  alias Backstop.Servers.State

  @impl true
  def init([module, args, parent]) do
    {:ok, %State{module: module,
                 env: module.environment(args),
                 command: module.command(args),
                 dir: directory(),
                 parent: parent,
                 args: args}}

  end

  @impl true
  def terminate(reason, %{port: port, module: module}) do
    Logger.info("shutting down #{module}...")
    :ok = kill_port(port)
    reason
  end

  @impl true
  def handle_cast(:start, %{dir: dir, env: env, command: command} = state) do
    port = Port.open(
      {:spawn, command},
      [
        :stderr_to_stdout,
        line: 65_536,
        cd: dir,
        env: env
      ])
    {:noreply, %{state | port: port}}
  end
  def handle_cast({:test_url, url}, state) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200}} -> :ok
      {:ok, %HTTPoison.Response{status_code: 302}} -> :ok
      response ->
        send_parent state, {:error, {:bad_response, url, response}}
    end
    {:noreply, state}
  end
  def handle_cast({:kill, error}, %{module: module} = state) when is_binary(error) do
    module_name = module
    |> Backstop.Servers.server_name()
    |> to_string()
    |> String.downcase()

    {stream, 0} = System.cmd("ps", ["ax"])

    :ok = stream
    |> String.split("\n")
    |> Enum.find(& String.downcase(&1) =~ module_name)
    |> kill_ghost_proc(error, module_name)

    GenServer.cast(state.parent, {:start_server, module})

    {:stop, :normal, state}
  end

  @spec kill_ghost_proc(String.t | nil, String.t, String.t) :: :ok | {:error, any}
  defp kill_ghost_proc(nil, error, _module_name), do: {:error, error}
  defp kill_ghost_proc(proc_info, error, module_name) do
    os_pid = proc_info
    |> String.split("  ")
    |> List.first()

    Logger.warn([error, "\n", proc_info, "\n", "Killing ghost ", module_name, " server at pid ", os_pid, " and restarting"])

    case System.cmd("kill", ["-9", os_pid]) do
      {_stream, 0} -> :ok
      error -> {:error, error}
    end
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({port, {:data, {_flag, data_list}}}, %{module: module, port: port} = state) do
    data = :erlang.iolist_to_binary(data_list)
    if state.args[:verbose] do
      :ok = log [server_name(module), " => ", data_list], module
    end
    if data =~ apply(module, :started_match, []) do
      send_parent(state, {:server_status, :ready})
    end
    if data =~ apply(module, :error_match, []) do
      send_parent(state, {:error, data})
    end
    {:noreply, state}
  end

  @spec send_parent(State.t, any) :: :ok
  defp send_parent(%{module: module, parent: parent}, message) do
    send parent, {module, self(), message}
  end

  @spec server_name(atom) :: String.t
  def server_name(module) do
    module
    |> Module.split
    |> List.last
  end

  @spec kill_port(port) :: :ok
  defp kill_port(port) when not is_nil(port) do
    case Port.info(port, :os_pid) do
      {:os_pid, pid} ->
        _ = System.cmd("kill", ["-9", Integer.to_string(pid)], stderr_to_stdout: true)
        :ok
      nil -> :ok
    end
  end

  @spec directory() :: String.t
  def directory do
    :site
    |> Application.app_dir
    |> String.replace("_build/#{Mix.env}/lib", "apps")
  end

  @spec log(iodata, atom) :: :ok | {:error, any}
  def log(iodata, module) do
    [module.log_color(), iodata, :reset]
    |> IO.ANSI.format_fragment(true)
    |> IO.iodata_to_binary()
    |> Logger.info
  end

  defmacro __using__([]) do
    quote do
      @behaviour unquote(__MODULE__)

      @spec start_link(map) :: {atom, pid}
      def start_link(args) do
        {:ok, pid} = GenServer.start_link(unquote(__MODULE__), [__MODULE__, args, self()])
        Process.monitor(pid)
        GenServer.cast(pid, :start)
        {__MODULE__, pid}
      end

      def environment(_), do: []

      def log_color, do: :white

      @spec test_url(String.t) :: :ok
      def test_url(url) do
        :ok = case HTTPoison.get(url) do
          {:ok, %HTTPoison.Response{status_code: 200}} -> :ok
          {:ok, %HTTPoison.Response{status_code: 302}} -> :ok
          error -> {:error, {:bad_response, error}}
        end
      end

      defoverridable [environment: 1, log_color: 0, test_url: 1]
    end
  end
end

defmodule Backstop.Servers.Phoenix do
  @moduledoc "Run the Phoenix server."

  require Logger
  use Backstop.Servers
  @default_args [
    {'V3_URL', 'http://localhost:8080'},
    {'GOOGLE_API_KEY', ''}
  ]

  @impl true
  def environment(%{dev: true}), do: @default_args
  def environment(_) do
    [
      {'MIX_ENV', 'prod'},
      {'STATIC_SCHEME', 'http'},
      {'STATIC_HOST', 'localhost'},
      {'STATIC_PORT', '8082'},
      {'PORT', '8082'}
      | @default_args
    ]
  end

  @impl true
  def command(args) do
    mode = if args[:dev], do: "dev", else: "prod"
    :ok = ["Starting Phoenix in ", mode, " mode with pid ", inspect(self()), "and args: ", inspect(args)]
    |> Backstop.Servers.log(__MODULE__)
    do_command(args)
  end

  defp do_command(%{dev: true}), do: "mix phoenix.server"
  defp do_command(_), do: "mix do deps.compile --force, compile --no-deps-check --force, phoenix.server"

  @impl true
  def log_color, do: :magenta

  @impl true
  def started_match do
    "Running Site.Endpoint"
  end

  @impl true
  def error_match do
    ~r/\[error\] (?!Supervisor|Could not find static manifest)/
  end
end

defmodule Backstop.Servers.Wiremock do
  @moduledoc "Run the Wiremock server."

  use Backstop.Servers

  @impl true
  def command(_) do
    :ok = ["starting Wiremock with pid ", inspect self()]
    |> Backstop.Servers.log(__MODULE__)

    "java -jar #{Application.get_env(:site, :wiremock_path)}"
  end

  @impl true
  def log_color, do: :light_green

  @impl true
  def started_match do
    "8080"
  end

  @impl true
  def error_match do
    ~r/(Address already in use)|(Unable to access jarfile)/
  end
end

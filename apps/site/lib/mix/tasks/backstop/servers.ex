defmodule Backstop.Servers do
  require Logger
  use GenServer

  @callback directory() :: String.t
  @callback environment() :: [{String.t, String.t | false}]
  @callback command() :: String.t
  @callback started_regex() :: String.t | Regex.t
  @callback error_regex() :: String.t | Regex.t

  defmodule State do
    @type t :: %__MODULE__{
      module: atom,
      parent: pid,
      port: port
    }
    defstruct [:module, :parent, :port]
  end

  alias Backstop.Servers.State

  def init([module, parent]) do
    port = Port.open(
      {:spawn, module.command},
      [:stderr_to_stdout,
       :exit_status,
       line: 65_536,
       cd: module.directory,
       env: remap_env(module.environment),
      ])

    {:ok, %State{module: module,
                 parent: parent,
                 port: port}}
  end

  def terminate(reason, %{port: port}) do
    :ok = kill_port(port)
    true = try do
             Port.close(port)
           rescue
             ArgumentError -> true
           end
    reason
  end

  def handle_info({port, {:data, {_flag, data_list}}}, %{module: module, port: port} = state) do
    data = :erlang.iolist_to_binary(data_list)
    IO.write [server_name(state), " => ", data, "\n"]
    if data =~ module.started_regex do
      send_parent(state, :started)
    end
    if data =~ module.error_regex do
      send_parent(state, :error)
    end
    {:noreply, state}
  end
  def handle_info({port, {:exit_status, _status}}, %{port: port} = state) do
    send_parent(state, :finished)
    {:stop, :normal, state}
  end
  def handle_info({parent, :shutdown}, %{parent: parent} = state) do
    _ = Logger.info "shutting down #{server_name(state)}"
    kill_port(state.port)
    send_parent(state, :finished)
    {:stop, :normal, state}
  end

  @spec send_parent(State.t, atom) :: :ok
  defp send_parent(%{parent: parent}, message) do
    send parent, {self(), message}
  end

  @spec server_name(State.t) :: String.t
  defp server_name(%{module: module}) do
    module
    |> Module.split
    |> List.last
  end

  @spec kill_port(port) :: :ok
  defp kill_port(port) do
    case Port.info(port, :os_pid) do
      {:os_pid, pid} ->
        _ = System.cmd("kill", [Integer.to_string(pid)], stderr_to_stdout: true)
        :ok
      nil -> :ok
    end
  end

  @spec remap_env([{String.t, String.t}]) :: [{charlist, charlist}]
  def remap_env(env) do
    env
    |> Enum.map(fn {name, val} ->
      {String.to_charlist(name), String.to_charlist(val)}
    end)
  end

  defmacro __using__([]) do
    quote location: :keep do
      require Logger

      @behaviour unquote(__MODULE__)

      def start_link(parent) do
        GenServer.start_link(unquote(__MODULE__), [__MODULE__, parent])
      end
    end
  end
end

defmodule Backstop.Servers.Phoenix do
  @moduledoc "Run the Phoenix server."

  use Backstop.Servers

  def directory do
    File.cwd!
  end

  def environment do
    [
      {"MIX_ENV", "prod"},
      {"PORT", "8082"},
      {"STATIC_SCHEME", "http"},
      {"STATIC_HOST", "localhost"},
      {"STATIC_PORT", "8082"},
      {"V3_URL", "http://localhost:8080"}
    ]
  end

  def command do
    "mix do clean, deps.compile, compile, phoenix.server"
  end

  def started_regex do
    "Running Site.Endpoint"
  end

  def error_regex do
    "[error]"
  end
end

defmodule Backstop.Servers.Wiremock do
  @moduledoc "Run the Wiremock server."

  use Backstop.Servers

  def directory do
    :site
    |> Application.app_dir
    |> String.replace("_build/#{Mix.env}/lib", "apps")
  end

  def environment do
    []
  end

  def command do
    "java -jar #{Application.get_env(:site, :wiremock_path)}"
  end

  def started_regex do
    ~R(port:\s+8080)
  end

  def error_regex do
    "Address already in use"
  end
end

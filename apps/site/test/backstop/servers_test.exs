defmodule Backstop.ServersTest do
  defmodule TestServer do
    use Backstop.Servers

    def command(%{dev: true}), do: "sh -c 'echo hellodev; sleep 10'"
    def command(_), do: "sh -c 'echo helloprod; sleep 10'"

    def started_match, do: "hello"

    def error_match, do: "error"
  end

  defmodule ErrorServer do
    use Backstop.Servers

    def command(_), do: "sh -c 'echo error; sleep 10'"

    def started_match, do: "value"

    def error_match, do: "error"
  end

  defmodule ListenerServer do
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, %{parent: self()})
    end

    def handle_call({:start_server, module, args}, _from, state) do
      {:reply, module.start_link(args), state}
    end

    def handle_info(info, state) do
      send state.parent, info
      {:noreply, state}
    end
  end

  use ExUnit.Case, async: true

  describe "GenServers" do
    setup do
      {:ok, pid} = ListenerServer.start_link()
      {:ok, listener: pid}
    end

    test "can run and finish", %{listener: listener} do
      assert {TestServer, server} = GenServer.call(listener, {:start_server, TestServer, %{}})
      assert_receive {TestServer, ^server, {:server_status, :ready}}
      assert %{command: "sh -c 'echo helloprod; sleep 10'"} = GenServer.call(server, :state)
      assert :ok = GenServer.stop(server)
    end

    test "runs dev mode command when dev: true", %{listener: listener} do
      assert {TestServer, server} = GenServer.call(listener, {:start_server, TestServer, %{dev: true}})
      assert_receive {TestServer, ^server, {:server_status, :ready}}
      assert %{command: "sh -c 'echo hellodev; sleep 10'", args: %{dev: true}} = GenServer.call(server, :state)
      assert :ok = GenServer.stop(server)
    end

    test "catches errors without shutting down", %{listener: listener} do
      assert {ErrorServer, server} = GenServer.call(listener, {:start_server, ErrorServer, %{}})
      assert_receive {ErrorServer, ^server, {:error, "error"}}
      assert Process.alive?(server)
      assert :ok = GenServer.stop(server)
    end
  end

  describe "error_match/0" do
    test "matches error strings" do
      assert "[error] something or other" =~ Backstop.Servers.Phoenix.error_match
      refute "[error] Supervisor 'Elixir.Logger.Supervisor'" =~ Backstop.Servers.Phoenix.error_match
      refute "[error] Could not find static manifest" =~ Backstop.Servers.Phoenix.error_match
      assert "Unable to access jarfile blah.jar" =~ Backstop.Servers.Wiremock.error_match
      assert "Address already in use" =~ Backstop.Servers.Wiremock.error_match
    end
  end

  test "wiremock command uses :wiremock_path config" do
    Application.put_env(:site, :wiremock_path, "path/to/wiremock")
    assert Backstop.Servers.Wiremock.command(%{}) == "java -jar path/to/wiremock"
    assert Backstop.Servers.Wiremock.command(%{dev: true}) == "java -jar path/to/wiremock"
  end
end

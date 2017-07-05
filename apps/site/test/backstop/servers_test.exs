defmodule Backstop.ServersTest do
  defmodule TestServer do
    use Backstop.Servers

    def environment do
      [{'VAR', 'value'}]
    end

    def command do
      "echo $VAR"
    end

    def started_match do
      "value"
    end

    def error_match do
      "goodbye"
    end
  end

  defmodule ErrorServer do
    use Backstop.Servers

    def command do
      "sh -c 'echo error; sleep 10'"
    end

    def started_match do
      "value"
    end

    def error_match do
      "error"
    end
  end

  use ExUnit.Case, async: true

  @tag :capture_log
  test "can run and finish" do
    {:ok, pid} = Backstop.ServersTest.TestServer.start_link()
    assert :started = Backstop.Servers.await(pid)
    assert :ok = Backstop.Servers.shutdown(pid)
    refute Process.alive? pid
    assert :ok = Backstop.Servers.shutdown(pid)
  end

  @tag :capture_log
  test "can handle an error" do
    {:ok, pid} = Backstop.ServersTest.ErrorServer.start_link()
    assert :error = Backstop.Servers.await(pid)
    assert :ok = Backstop.Servers.shutdown(pid)
    refute Process.alive? pid
    assert :ok = Backstop.Servers.shutdown(pid)
  end

  @tag :capture_log
  describe "run_with_pids/2" do
    test "returns fn status code if servers start" do
      {:ok, pid} = Backstop.ServersTest.TestServer.start_link()
      assert Backstop.Servers.Helpers.run_with_pids([pid], %{}, fn _ -> 2 end) == {2, [pid]}
    end

    test "returns 1 if the server fails to start" do
      {:ok, pid} = Backstop.ServersTest.ErrorServer.start_link()
      assert Backstop.Servers.Helpers.run_with_pids([pid], %{}, fn _ -> 2 end) == {1, [pid]}
    end
  end

  describe "error_match/0" do
    test "matches error strings" do
      assert "[error] something or other" =~ Backstop.Servers.Phoenix.error_match
      refute "[error] Supervisor 'Elixir.Logger.Supervisor'" =~ Backstop.Servers.Phoenix.error_match
      assert "Unable to access jarfile blah.jar" =~ Backstop.Servers.Wiremock.error_match
      assert "Address already in use" =~ Backstop.Servers.Wiremock.error_match
    end
  end

  test "wiremock command uses :wiremock_path config" do
    Application.put_env(:site, :wiremock_path, "path/to/wiremock")
    assert Backstop.Servers.Wiremock.command == "java -jar path/to/wiremock"
  end
end

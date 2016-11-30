defmodule Backstop.ServersTest do
  defmodule TestServer do
    use Backstop.Servers

    def directory do
      File.cwd!
    end

    def environment do
      [{'VAR', 'value'}]
    end

    def command do
      "echo $VAR"
    end

    def started_regex do
      "value"
    end

    def error_regex do
      "goodbye"
    end
  end

  defmodule ErrorServer do
    use Backstop.Servers

    def directory do
      File.cwd!
    end

    def environment do
      []
    end

    def command do
      "echo error"
    end

    def started_regex do
      "value"
    end

    def error_regex do
      "error"
    end
  end

  use ExUnit.Case, async: true

  @tag :capture_log
  test "can run and finish" do
    {:ok, pid} = Backstop.ServersTest.TestServer.start_link
    assert :started = Backstop.Servers.await(pid)
    assert :finished = Backstop.Servers.shutdown(pid)
    refute Process.alive? pid
  end

  @tag :capture_log
  test "can handle an error" do
    {:ok, pid} = Backstop.ServersTest.ErrorServer.start_link
    assert :error = Backstop.Servers.await(pid)
    assert :finished = Backstop.Servers.shutdown(pid)
    refute Process.alive? pid
  end
end

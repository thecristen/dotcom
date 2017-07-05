defmodule Mix.Tasks.Backstop.TestsTest do
  use ExUnit.Case, async: true

  defmodule TestServer do
    use GenServer
    def start_link do
      GenServer.start_link(__MODULE__, [self()], [name: __MODULE__])
    end

    def init([parent]) do
      send parent, {:started, self()}
      {:ok, %{parent: parent, status: :waiting}}
    end

    def handle_call(:start, _from, state) do
      {:reply, :started, %{state | status: :started}}
    end

    def handle_call(:state, _from, %{parent: parent} = state) do
      send parent, state
      {:reply, state, state}
    end
  end

  def runner_fn(args_map) do
    state = GenServer.call(TestServer, :state)
    send self(), {"runner called", args_map, state}
    0
  end

  def await_fn(pid) do
    GenServer.call(pid, :start)
  end

  describe "run/1" do
    test "starts servers and calls the runner task" do
      assert {:ok, [pid]} = Mix.Tasks.Backstop.Tests.run([], [TestServer], &runner_fn/1, &await_fn/1)
      assert_receive {:started, ^pid}
      assert_receive {"runner called", args, state}
      assert state == %{status: :started, parent: self()}
      assert args == %{}
    end

    test "turns arguments into a map" do
      assert {:ok, [_pid]} =
        Mix.Tasks.Backstop.Tests.run([~s(--filter="Homepage")], [TestServer], &runner_fn/1, &await_fn/1)
      assert_receive {"runner called", args, _state}
      assert args == %{"--filter" => ~s("Homepage")}
    end
  end

  def cmd_fn(cmd, args, _opts) do
    send self(), {"cmd args", cmd, args}
    {:ok, 2}
  end


  describe "run_backstop/2" do
    test "runs backstop with filter when --filter option is used" do
      assert Mix.Tasks.Backstop.Tests.run_backstop(%{"--filter" => "Homepage"}, &cmd_fn/3) == 2
      assert_receive {"cmd args", cmd, args}
      assert cmd =~ "apps/site/node_modules/.bin/backstop"
      assert args == ["test", "--filter=Homepage", "--config=apps/site/backstop.json"]
    end

    test "runs backstop without filter if --filter option is not used" do
      assert Mix.Tasks.Backstop.Tests.run_backstop(%{}, &cmd_fn/3) == 2
      assert_receive {"cmd args", _cmd, args}
      assert args == ["test", "--config=apps/site/backstop.json"]
    end

    test "returns 1 if process fails with a RuntimeError" do
      error_fn = fn _, _, _ ->
        raise RuntimeError
      end
      error = ExUnit.CaptureLog.capture_log fn ->
        assert Mix.Tasks.Backstop.Tests.run_backstop(%{}, error_fn)
      end
      assert error =~ "Backstop did not start; shutting down"
    end
  end
end

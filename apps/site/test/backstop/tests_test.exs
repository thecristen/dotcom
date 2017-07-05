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
end

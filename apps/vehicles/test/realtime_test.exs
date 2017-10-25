defmodule Vehicles.RealtimeTest do
  use ExUnit.Case, async: true

  def routes_fn do
    pid = self()
    fn ->
      send pid, "routes function called"
      [%Routes.Route{id: "Magenta"}]
    end
  end

  def vehicles_fn do
    pid = self()
    fn route_id, [direction_id: direction_id] ->
      send pid, "vehicles function called"
      [%Vehicles.Vehicle{id: "vehicle1", route_id: route_id, stop_id: "stop1", direction_id: direction_id, status: :in_transit}]
    end
  end

  describe "register/2" do
    test "registers a process for a route and direction" do
      assert {:ok, pid} = Vehicles.Realtime.register("Magenta", 0)
      assert is_pid(pid)
      Registry.dispatch Vehicles.Registry, {:route, "Magenta", 0}, fn [{pid, %{}}] ->
        send pid, "hello from Registry.dispatch"
      end
      assert_receive "hello from Registry.dispatch"
    end
  end

  test "is started by supervisor" do
    assert {:error, {:already_started, pid}} = Vehicles.Realtime.start_link()
    assert is_pid(pid)
  end

  test "updates registry subscribers when GenServer is updated" do
    opts = %{
      vehicles_repo_fn: vehicles_fn(),
      routes_repo_fn: routes_fn(),
      interval: 50
    }
    {:ok, _pid} = GenServer.start_link(Vehicles.Realtime, opts)

    assert {:ok, _} = Vehicles.Realtime.register("Magenta", 1)
    assert_receive "routes function called"
    assert_receive "vehicles function called"
    assert_receive {:vehicles, %{route_id: "Magenta", direction_id: 1}, vehicles}
    assert vehicles == [%Vehicles.Vehicle{id: "vehicle1", route_id: "Magenta", direction_id: 1, status: :in_transit, stop_id: "stop1"}]
  end

  test "does not call Vehicles repo if no pids are subscribed for route & direction" do
    opts = %{
      vehicles_repo_fn: vehicles_fn(),
      routes_repo_fn: routes_fn(),
      interval: 50
    }
    {:ok, _pid} = GenServer.start_link(Vehicles.Realtime, opts)
    assert Registry.lookup(Vehicles.Registry, {:route, "Magenta", 1}) == []
    assert_receive "routes function called"
    refute_receive "vehicles function called"
    refute_receive {:vehicles, _, _}
  end

  test "does not ping subscribers when there are no vehicles" do
    pid = self()
    opts = %{
      vehicles_repo_fn: fn _, _ ->
        send pid, "vehicles function called"
        []
      end,
      routes_repo_fn: routes_fn(),
      interval: 50
    }
    {:ok, _pid} = GenServer.start_link(Vehicles.Realtime, opts)
    assert {:ok, _} = Vehicles.Realtime.register("Magenta", 1)
    assert_receive "routes function called"
    assert_receive "vehicles function called"
    refute_receive {:vehicles, _, _}
  end
end

defmodule Vehicles.Repo do
  use GenServer
  alias Vehicles.Vehicle

  @spec route(String.t(), Keyword.t()) :: [Vehicle.t()]
  def route(route_id, opts \\ []) do
    {cache, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.call(cache, {:route, route_id, opts})
  end

  @spec trip(String.t()) :: Vehicle.t() | nil
  def trip(trip_id, opts \\ []) do
    opts
    |> Keyword.get(:name, __MODULE__)
    |> GenServer.call({:trip_id, trip_id})
  end

  @spec all(keyword(String.t())) :: [Vehicle.t()]
  def all(opts \\ []) do
    opts
    |> Keyword.get(:name, __MODULE__)
    |> GenServer.call(:all)
  end

  #
  # GenServer internal methods
  #

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @impl GenServer
  def init(opts) do
    ets_name =
      opts
      |> Keyword.fetch!(:name)
      |> Module.concat(ETS)

    ets = :ets.new(ets_name, [])

    pubsub_fn = Keyword.get(opts, :pubsub_fn, &Phoenix.PubSub.subscribe/2)
    _ = pubsub_fn.(Vehicles.PubSub, "vehicles")
    {:ok, %{ets: ets}}
  end

  @impl GenServer
  def handle_call(:all, _from, %{ets: ets} = state) do
    vehicles =
      ets
      |> :ets.tab2list()
      |> Enum.map(fn {_id, _route, _dir, _trip, %Vehicle{} = v} -> v end)

    {:reply, vehicles, state}
  end

  def handle_call({:trip_id, trip_id}, _from, state) do
    vehicle =
      case :ets.match(state.ets, {:_, :_, :_, trip_id, :"$1"}) do
        [[trip]] -> trip
        [] -> nil
      end

    {:reply, vehicle, state}
  end

  def handle_call({:route, route_id, opts}, _from, state) do
    direction_id =
      case Keyword.fetch(opts, :direction_id) do
        {:ok, dir} -> dir
        :error -> :_
      end

    vehicles =
      state.ets
      |> :ets.match({:_, route_id, direction_id, :_, :"$1"})
      |> List.flatten()

    {:reply, vehicles, state}
  end

  @impl GenServer
  def handle_info({:reset, vehicles}, state) do
    _ = :ets.delete_all_objects(state.ets)
    [] = :ets.tab2list(state.ets)
    _ = add_vehicles(vehicles, state.ets)
    {:noreply, state}
  end

  def handle_info({:add, [%Vehicle{} = vehicle]}, state) do
    _ = add_vehicles([vehicle], state.ets)
    {:noreply, state}
  end

  def handle_info({:update, [%Vehicle{} = vehicle]}, %{ets: ets} = state) do
    _ = add_vehicles([vehicle], ets)
    {:noreply, state}
  end

  def handle_info({:remove, [<<id::binary>>]}, %{ets: ets} = state) do
    _ = :ets.delete(ets, id)
    {:noreply, state}
  end

  @spec add_vehicles([Vehicle.t()], atom) :: true
  defp add_vehicles(vehicles, tab) when is_list(vehicles) do
    items =
      for vehicle <- vehicles do
        {
          vehicle.id,
          vehicle.route_id,
          vehicle.direction_id,
          vehicle.trip_id,
          vehicle
        }
      end

    :ets.insert(tab, items)
  end
end

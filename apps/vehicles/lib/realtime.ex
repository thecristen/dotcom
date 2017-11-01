defmodule Vehicles.Realtime do
  @moduledoc """
  Fetches vehicles from the repo every 10 seconds.

  Processes can subscribe to get updates when new vehicles are fetched by calling `&Vehicles.Realtime.register/2`.
  When updates are available, registered processes will be sent
  {:vehicles, %{route_id: _, direction_id: _}, [vehicles]}.
  """

  use GenServer

  @type routes_repo_fn :: (() -> [Routes.Route.t])
  @type vehicles_repo_fn :: (Routes.Route.id_t, [direction_id: integer] -> [Vehicles.Vehicle.t])
  @type opts :: [routes_repo_fn: routes_repo_fn,
                 vehicles_repo_fn: vehicles_repo_fn,
                 interval: integer]

  @default_opts [
    routes_repo_fn: &Routes.Repo.all/0,
    vehicles_repo_fn: &Vehicles.Repo.route/2,
    interval: 10_000
  ]

  @spec start_link(opts) :: GenServer.on_start
  def start_link(opts \\ []) when is_list(opts) do
    args = @default_opts
           |> Keyword.merge(opts)
           |> Enum.into(%{})
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec register(Routes.Route.id_t, integer) :: {:ok, pid}
  def register(route_id, direction_id) do
    Registry.register(Vehicles.Registry, {:route, route_id, direction_id}, %{})
  end

  @spec unregister(Routes.Route.id_t, integer) :: :ok
  def unregister(route_id, direction_id) do
    Registry.unregister(Vehicles.Registry, {:route, route_id, direction_id})
  end

  @impl true
  def init(%{routes_repo_fn: _, vehicles_repo_fn: _, interval: _} = opts) do
    send self(), :update
    {:ok, opts}
  end

  @impl true
  def handle_info(:update, %{routes_repo_fn: routes_fn, interval: interval} = opts) do
    Enum.each(routes_fn.(), &send(self(), {:update_route, &1}))
    Process.send_after(self(), :update, interval)

    {:noreply, opts}
  end

  def handle_info({:update_route, %Routes.Route{id: route_id}}, %{vehicles_repo_fn: vehicles_fn} = state) do
    for direction_id <- [0, 1] do
      channel = {:route, route_id, direction_id}
      Registry.dispatch Vehicles.Registry, channel, &update_route(&1, route_id, direction_id, vehicles_fn)
    end

    {:noreply, state}
  end

  @spec update_route([{pid, any}], Routes.Route.id_t, integer, vehicles_repo_fn) :: :ok
  defp update_route([], _, _, _), do: :ok
  defp update_route(subscribers, route_id, direction_id, vehicles_fn) do
    route_id
    |> vehicles_fn.(direction_id: direction_id)
    |> do_update_route(subscribers, route_id, direction_id)
  end

  @spec do_update_route([Vehicles.Vehicle.t], [{pid, any}], Routes.Route.id_t, integer) :: :ok
  defp do_update_route([], _, _, _), do: :ok
  defp do_update_route(vehicles, subscribers, route_id, direction_id) when is_list(vehicles) do
    for {pid, _} <- subscribers, do: send pid, {:vehicles, %{route_id: route_id, direction_id: direction_id}, vehicles}
    :ok
  end
end

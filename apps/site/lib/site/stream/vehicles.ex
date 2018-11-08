defmodule Site.Stream.Vehicles do
  use GenServer
  alias Vehicles.Vehicle

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [repo: Vehicles.Repo], name: name)
  end

  def init(opts) do
    {:ok, repo} = Keyword.fetch(opts, :repo)
    send self(), :heartbeat
    {:ok, %{repo: repo}}
  end

  def handle_info(:heartbeat, %{repo: repo} = state) do
    by_route =
      repo.all()
      |> Enum.group_by(& {&1.route_id, &1.direction_id})
      |> Enum.reject(fn {route_id, _} -> route_id == nil end)
      |> Map.new()

    _ = send_green_line(by_route)

    Enum.each(by_route, &send_vehicles/1)

    Process.send_after self(), :heartbeat, 5_000
    {:noreply, state}
  end

  @type vehicle_map :: %{optional(Routes.Route.id_t) => [Vehicle.t]}

  @spec send_green_line(vehicle_map) :: :ok
  defp send_green_line(by_route) do
    Enum.each([0, 1], fn direction_id ->
      GreenLine.branch_ids()
      |> Enum.flat_map(& Map.get(by_route, {&1, direction_id}, []))
      |> do_send_green_line(direction_id)
    end)
  end

  @spec do_send_green_line([Vehicle.t], 0 | 1) :: :ok
  defp do_send_green_line(vehicles, direction_id) do
    send_vehicles({{"Green", direction_id}, vehicles})
  end

  @spec send_vehicles({{Routes.Route.id_t, 0 | 1}, [Vehicle.t]}) :: :ok
  defp send_vehicles({{<<route_id::binary>>, direction_id}, vehicles}) when direction_id in [0, 1] do
    SiteWeb.Endpoint.broadcast(
      "vehicles:" <> route_id <> ":" <> Integer.to_string(direction_id),
      "data",
      %{data: vehicles}
    )
  end
  defp send_vehicles(_) do
    :ok
  end
end

defmodule Site.Stream.Vehicles do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [repo: Vehicles.Repo], name: __MODULE__)
  end

  def init(opts) do
    {:ok, repo} = Keyword.fetch(opts, :repo)
    send self(), :heartbeat
    {:ok, %{repo: repo}}
  end

  def handle_info(:heartbeat, %{repo: repo} = state) do
    []
    |> repo.fetch()
    |> Enum.group_by(& {&1.route_id, &1.direction_id})
    |> Enum.each(&send_vehicles/1)

    Process.send_after self(), :heartbeat, 5_000
    {:noreply, state}
  end

  defp send_vehicles({{<<route_id::binary>>, direction_id}, vehicles}) when direction_id in [0, 1] do
    SiteWeb.Endpoint.broadcast(
      "vehicles:" <> route_id <> ":" <> Integer.to_string(direction_id),
      "vehicles",
      %{data: vehicles}
    )
  end
  defp send_vehicles(_) do
    :ok
  end
end

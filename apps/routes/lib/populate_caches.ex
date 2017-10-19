defmodule Routes.PopulateCaches do
  @moduledoc """
  Populate the Routes.Repo cache out-of-band.
  """
  use GenServer

  @repeat_after :timer.hours(24)

  @spec start_link([]) :: GenServer.on_start
  def start_link([]) do
    GenServer.start_link(__MODULE__, Routes.Repo) # no cover
  end

  @impl GenServer
  def init(repo_mod) do
    send self(), :populate_all
    {:ok, repo_mod}
  end

  @impl GenServer
  def handle_info(:populate_all, repo_mod) do
    all_routes = repo_mod.all()
    for route <- all_routes do
      _ = repo_mod.headsigns(route.id)
      for direction_id <- [0, 1] do
        _ = repo_mod.get_shapes(route.id, direction_id)
      end
    end

    Process.send_after(self(), :populate_all, @repeat_after)
    {:noreply, repo_mod}
  end
  def handle_info(msg, state) do
    super(msg, state)
  end
end

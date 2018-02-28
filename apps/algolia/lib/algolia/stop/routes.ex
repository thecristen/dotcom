defmodule Algolia.Stop.Routes do
  @type t :: [Algolia.Stop.Route.t]

  @spec for_stop(Stops.Stop.id_t) :: [__MODULE__.t]
  def for_stop(stop_id, repo_fn \\ &Routes.Repo.by_stop/1) when is_binary(stop_id) do
    stop_id
    |> repo_fn.()
    |> do_for_stop()
  end

  @spec do_for_stop([Routes.Route.t]) :: [__MODULE__.t]
  defp do_for_stop(routes) do
    routes
    |> Enum.map(&Routes.Route.icon_atom/1)
    |> Enum.uniq()
    |> Enum.map(&Algolia.Stop.Route.new(&1, routes))
  end
end

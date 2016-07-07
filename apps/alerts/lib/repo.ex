defmodule Alerts.Repo do
  use RepoCache, ttl: :timer.minutes(1)

  def all do
    cache [], fn _ ->
      V3Api.Alerts.all.data
      |> Enum.map(&Alerts.Parser.parse/1)
    end
  end

  def by_id(id) do
    all
    |> Enum.find(&(&1.id == id))
  end
end

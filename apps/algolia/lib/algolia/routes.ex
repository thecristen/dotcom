defmodule Algolia.Routes do
  @behaviour Algolia.Index

  @repo :algolia
        |> Application.get_env(:repos)
        |> Keyword.fetch!(:routes)

  @impl Algolia.Index
  def all do
    [@repo.green_line() | @repo.all()]
  end

  @impl Algolia.Index
  def index_name, do: "routes"
end

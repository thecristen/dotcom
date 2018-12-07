defmodule Content.Factory do
  alias Content.CMS.Static
  alias Content.{Event, NewsEntry, Person, Project, ProjectUpdate, Teaser}

  @spec event_factory(integer, map) :: Event.t()
  def event_factory(index, opts \\ []) when is_integer(index) do
    Static.events_response()
    |> Enum.at(index)
    |> Event.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec news_entry_factory(integer, map) :: NewsEntry.t()
  def news_entry_factory(index, opts \\ []) when is_integer(index) do
    Static.news_response()
    |> Enum.at(index)
    |> NewsEntry.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec news_entry_teaser_factory(integer, map) :: Teaser.t()
  def news_entry_teaser_factory(index, opts \\ []) when is_integer(index) do
    Static.news_teaser_response()
    |> Enum.at(index)
    |> Teaser.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec project_factory(integer, map) :: Project.t()
  def project_factory(index, opts \\ []) when is_integer(index) do
    Static.projects_response()
    |> Enum.at(index)
    |> Project.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec project_update_factory(integer, map) :: ProjectUpdate.t()
  def project_update_factory(index, opts \\ []) when is_integer(index) do
    Static.project_updates_response()
    |> Enum.at(index)
    |> ProjectUpdate.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec person_factory(map) :: Person.t()
  def person_factory(opts \\ []) do
    Static.person_response()
    |> Person.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end
end

defmodule Content.Factory do
  @spec event_factory(integer, map) :: Content.Event.t
  def event_factory(index, opts \\ []) when is_integer(index) do
    Content.CMS.Static.events_response()
    |> Enum.at(index)
    |> Content.Event.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec news_entry_factory(integer, map) :: Content.NewsEntry.t
  def news_entry_factory(index, opts \\ []) when is_integer(index) do
    Content.CMS.Static.news_response()
    |> Enum.at(index)
    |> Content.NewsEntry.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec project_factory(integer, map) :: Content.Project.t
  def project_factory(index, opts \\ []) when is_integer(index) do
    Content.CMS.Static.projects_response()
    |> Enum.at(index)
    |> Content.Project.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec project_update_factory(integer, map) :: Content.ProjectUpdate.t
  def project_update_factory(index, opts \\ []) when is_integer(index) do
    Content.CMS.Static.project_updates_response()
    |> Enum.at(index)
    |> Content.ProjectUpdate.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec person_factory(map) :: Content.Person.t
  def person_factory(opts \\ []) do
    Content.CMS.Static.person_response()
    |> Content.Person.from_api()
    |> Map.merge(Enum.into(opts, %{}))
  end
end

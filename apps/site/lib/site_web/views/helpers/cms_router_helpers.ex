defmodule SiteWeb.CmsRouterHelpers do
  @moduledoc """
  A replacement module for path helpers from RouterHelpers.
  This allows us to use either a path_alias if it exists 
  to fetch from the CMS. If no path_alias exists, we will 
  fetch using "/type/:id" In the case where we are using the
  id, we delegate to the Phoeniox helpers from RouterHelpers.
  """
  alias SiteWeb.Router.Helpers, as: RouterHelpers

  @spec news_entry_path(Plug.Conn.t, atom, Keyword.t | Content.NewsEntry.t | String.t) :: String.t
  def news_entry_path(conn, verb, opts \\ [])
  def news_entry_path(conn, :index, opts) do
    RouterHelpers.news_entry_path(conn, :index, opts)
  end
  def news_entry_path(conn, :show, %Content.NewsEntry{path_alias: nil} = news_entry) do
    check_preview(conn, RouterHelpers.news_entry_path(conn, :show, [to_string(news_entry.id)]))
  end
  def news_entry_path(conn, :show, %Content.NewsEntry{} = news_entry) do
    check_preview(conn, news_entry.path_alias)
  end
  def news_entry_path(conn, :show, value) when is_binary(value) do
    check_preview(conn, RouterHelpers.news_entry_path(conn, :show, [value]))
  end

  @spec news_entry_path(Plug.Conn.t, atom, String.t, String.t) :: String.t
  def news_entry_path(conn, :show, date, title) do
    check_preview(conn, RouterHelpers.news_entry_path(conn, :show, [date, title]))
  end

  @spec event_path(Plug.Conn.t, atom, Keyword.t | Content.Event.t | String.t) :: String.t
  def event_path(conn, verb, opts \\ [])
  def event_path(conn, :index, opts) do
    RouterHelpers.event_path(conn, :index, opts)
  end
  def event_path(conn, :show, %Content.Event{path_alias: nil} = event) do
    check_preview(conn, RouterHelpers.event_path(conn, :show, [to_string(event.id)]))
  end
  def event_path(conn, :show, %Content.Event{} = event) do
    check_preview(conn, event.path_alias)
  end
  def event_path(conn, :show, value) when is_binary(value) do
    check_preview(conn, RouterHelpers.event_path(conn, :show, [value]))
  end

  @spec event_path(Plug.Conn.t, atom, String.t, String.t) :: String.t
  def event_path(conn, :show, date, title) do
    check_preview(conn, RouterHelpers.event_path(conn, :show, [date, title]))
  end

  @spec project_path(Plug.Conn.t, atom, Keyword.t | Content.Project.t | String.t) :: String.t
  def project_path(conn, verb, opts \\ [])
  def project_path(conn, :index, opts) do
    RouterHelpers.project_path(conn, :index, opts)
  end
  def project_path(conn, :show, %Content.Project{path_alias: nil} = project) do
    check_preview(conn, RouterHelpers.project_path(conn, :show, project.id))
  end
  def project_path(conn, :show, %Content.Project{} = project) do
    check_preview(conn, project.path_alias)
  end
  def project_path(conn, :show, value) when is_binary(value) do
    check_preview(conn, RouterHelpers.project_path(conn, :show, value))
  end

  @spec project_update_path(Plug.Conn.t, atom, Content.ProjectUpdate.t) :: String.t
  def project_update_path(conn, :project_update, %Content.ProjectUpdate{path_alias: nil} = project_update) do
    check_preview(conn, RouterHelpers.project_path(conn, :project_update, project_update.project_id, project_update.id))
  end
  def project_update_path(conn, :project_update, %Content.ProjectUpdate{} = project_update) do
    check_preview(conn, project_update.path_alias)
  end

  @spec project_update_path(Plug.Conn.t, atom, String.t, String.t) :: String.t
  def project_update_path(conn, :show, project, update) do
    check_preview(conn, "/projects/#{project}/update/#{update}")
  end

  @spec check_preview(Plug.Conn.t, String.t) :: String.t
  defp check_preview(conn, path), do: SiteWeb.ViewHelpers.cms_static_page_path(conn, path)
end

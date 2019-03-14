defmodule SiteWeb.StopController do
  @moduledoc """
  Page for display of information about in individual stop or station.
  """
  use SiteWeb, :controller
  alias Plug.Conn
  alias Routes.{Group, Route}
  alias SiteWeb.StopController.StopMap
  alias Stops.{Repo, Stop}
  alias Util.AndOr

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"stop" => stop}) do
    if Laboratory.enabled?(conn, :stop_page_redesign) do
      stop =
        stop
        |> URI.decode_www_form()
        |> Repo.get()

      if stop do
        routes_by_stop = Routes.Repo.by_stop(stop.id)
        grouped_routes = grouped_routes(routes_by_stop)
        routes_map = routes_map(grouped_routes)

        conn
        |> assign(:grouped_routes, grouped_routes)
        |> assign(:routes, routes_map)
        |> meta_description(stop, routes_by_stop)
        |> assign(:requires_google_maps?, true)
        |> assign(:map_data, StopMap.map_info(stop, routes_map))
        |> render("show.html", stop: stop)
      else
        check_cms_or_404(conn)
      end
    else
      render_404(conn)
    end
  end

  @spec grouped_routes([Route.t()]) :: [{Route.gtfs_route_type(), [Route.t()]}]
  defp grouped_routes(routes) do
    routes
    |> Enum.group_by(&Route.type_atom/1)
    |> Enum.sort_by(&Group.sorter/1)
  end

  def routes_map(grouped_routes) do
    grouped_routes
    |> Enum.map(fn {group, routes} -> %{group_name: group, routes: routes} end)
  end

  @spec meta_description(Conn.t(), Stop.t(), [Route.t()]) :: Conn.t()
  defp meta_description(conn, stop, routes),
    do:
      assign(
        conn,
        :meta_description,
        "Station serving MBTA #{lines(routes)} lines#{location(stop)}."
      )

  @spec lines([Route.t()]) :: iolist
  defp lines(routes) do
    routes
    |> Enum.map(&(&1.type |> Route.type_atom() |> Route.type_name()))
    |> Enum.uniq()
    |> AndOr.join(:and)
  end

  @spec location(Stop.t()) :: String.t()
  defp location(stop) do
    if stop.address && stop.address != "" do
      " at #{stop.address}"
    else
      ""
    end
  end
end

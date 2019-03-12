defmodule SiteWeb.StopController do
  @moduledoc """
  Page for display of information about in individual stop or station.
  """
  use SiteWeb, :controller

  alias Plug.Conn
  alias Routes.{Group, Route}
  alias Stops.{Repo, Stop}
  alias Util.AndOr

  def show(conn, %{"stop" => stop}) do
    if Laboratory.enabled?(conn, :stop_page_redesign) do
      stop =
        stop
        |> URI.decode_www_form()
        |> Repo.get()

      if stop do
        routes = Routes.Repo.by_stop(stop.id)

        conn
        |> assign(:grouped_routes, Task.async(fn -> grouped_routes(routes) end))
        |> meta_description(stop, routes)
        |> await_assign_all()
        |> render("show.html", stop: stop)
      else
        check_cms_or_404(conn)
      end
    else
      render_404(conn)
    end
  end

  @spec grouped_routes([Route.t()]) :: [{Route.gtfs_route_type(), Route.t()}]
  defp grouped_routes(routes) do
    routes
    |> Enum.group_by(&Route.type_atom/1)
    |> Enum.sort_by(&Group.sorter/1)
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

defmodule Site.PageController do
  use Site.Web, :controller

  plug Site.Plugs.Date
  plug Site.Plugs.Alerts

  def index(conn, %{"location" => %{"address" => address}}) do
    results = address
    |> GoogleMaps.Geocode.geocode
    |> Site.ServiceNearMeController.get_stops_nearby(conn)
    |> Site.ServiceNearMeController.stops_with_routes

    conn
    |> async_assign(:grouped_routes, &grouped_routes/0)
    |> assign(:stops_with_routes, results)
    |> assign(:address, address)
    |> async_assign(:news, &news/0)
    |> await_assign_all
    |> render("index.html")
  end
  def index(conn, _) do
    conn
    |> async_assign(:grouped_routes, &grouped_routes/0)
    |> assign(:stops_with_routes, [])
    |> assign(:address, "")
    |> async_assign(:news, &news/0)
    |> await_assign_all
    |> render("index.html")
  end

  defp news do
    News.Repo.all(limit: 3)
  end

  defp grouped_routes do
    Routes.Repo.all
    |> Routes.Group.group
  end

  def address({:ok, [%{formatted: address} | _]}) do
    address
  end
  def address(_), do: ""
end

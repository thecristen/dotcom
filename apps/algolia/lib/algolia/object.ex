defprotocol Algolia.Object do
  def object_id(obj)
  def data(obj)
  def url(obj)
end

defimpl Algolia.Object, for: Stops.Stop do
  def object_id(stop), do: "stop-" <> stop.id
  def url(stop), do: SiteWeb.Router.Helpers.stop_path(SiteWeb.Endpoint, :show, stop)
  def data(stop) do
    %{
      _geoloc: %{
        lat: stop.latitude,
        lng: stop.longitude
      },
      stop: stop,
      zone: Zones.Repo.get(stop.id),
      routes: Algolia.Stop.Routes.for_stop(stop.id),
      features: Stops.Repo.stop_features(stop)
    }
  end
end

defimpl Algolia.Object, for: Routes.Route do
  def object_id(route), do: "route-" <> route.id
  def url(route), do: SiteWeb.Router.Helpers.schedule_path(SiteWeb.Endpoint, :show, route)
  def data(%Routes.Route{direction_names: direction_names} = route) do
    # Poison can't parse maps with integer keys
    direction_names = [direction_names[0], direction_names[1]]

    %{
      route: %{route | direction_names: direction_names}
    }
  end
end

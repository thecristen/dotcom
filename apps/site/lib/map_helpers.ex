defmodule Site.MapHelpers do
  alias Routes.Route
  alias GoogleMaps.MapData.Marker
  import Site.Router.Helpers

  @spec map_pdf_url(integer | atom) :: String.t | nil
  def map_pdf_url(mode_number) when mode_number in 0..4 do
    mode_number
    |> Route.type_atom
    |> map_pdf_url
  end
  def map_pdf_url(:subway) do
    "https://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Rapid%20Transit%20w%20Key%20Bus.pdf"
  end
  def map_pdf_url(:bus) do
    "https://www.mbta.com/uploadedFiles/Schedules_and_Maps/System_Map/MBTA-system_map-back.pdf"
  end
  def map_pdf_url(:ferry) do
    "https://s3.amazonaws.com/mbta-dotcom/Water_Ferries_2016.pdf"
  end
  def map_pdf_url(:commuter_rail) do
    "https://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter%20Rail%20Map.pdf"
  end
  def map_pdf_url(_) do
    nil
  end

  @spec map_image_url(integer | atom) :: String.t | nil
  def map_image_url(mode_number) when mode_number in 0..4 do
    mode_number
    |> Route.type_atom
    |> map_image_url
  end
  def map_image_url(:commuter_rail) do
    "/images/commuter-rail-spider.jpg"
  end
  def map_image_url(:ferry) do
    "/images/ferry-spider.jpg"
  end
  def map_image_url(:bus) do
    "/images/mbta-full-system-map.jpg"
  end
  def map_image_url(_) do
    "/images/subway-spider.jpg"
  end

  @doc "Returns the map color that should be used for the given route"
  # The Ferry color: 5DA9E8 isn't used on any maps right now.
  @spec route_map_color(Route.t | nil) :: String.t
  def route_map_color(%Route{type: 3}), do: "FFCE0C"
  def route_map_color(%Route{type: 2}), do: "A00A78"
  def route_map_color(%Route{id: "Blue"}), do: "0064C8"
  def route_map_color(%Route{id: "Red"}), do: "FF1428"
  def route_map_color(%Route{id: "Mattapan"}), do: "FF1428"
  def route_map_color(%Route{id: "Orange"}), do: "FF8200"
  def route_map_color(%Route{id: "Green" <> _}), do: "428608"
  def route_map_color(_), do: "000000"

  @doc """
  Returns the map icon path for the given route. An optional size
  can be given. A Size of :mid represents the larger stop icons.
  If no size is specified, the smaller icons are shown
  """
  @spec map_stop_icon_path(Route.t | nil, Marker.size | nil) :: String.t
  def map_stop_icon_path(route, size \\ nil)
  def map_stop_icon_path(route, :mid) do
    static_url(Site.Endpoint, "/images/map-#{route_map_color(route)}-dot-icon-mid.png")
  end
  def map_stop_icon_path(route, _size) do
    static_url(Site.Endpoint, "/images/map-#{route_map_color(route)}-dot-icon.png")
  end
end

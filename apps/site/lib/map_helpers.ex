defmodule Site.MapHelpers do
  alias Routes.Route
  alias GoogleMaps.MapData.Marker

  import Site.Router.Helpers, only: [static_url: 2]

  @spec map_pdf_url(integer | atom) :: String.t | nil
  def map_pdf_url(mode_number) when mode_number in 0..4 do
    mode_number
    |> Route.type_atom
    |> map_pdf_url
  end
  def map_pdf_url(:subway) do
    static_url(Site.Endpoint, "/sites/default/files/maps/Rapid_Transit_Map.pdf")
  end
  def map_pdf_url(:bus) do
    static_url(Site.Endpoint, "/sites/default/files/maps/Full_System_Map.pdf")
  end
  def map_pdf_url(:commuter_rail) do
    static_url(Site.Endpoint, "/sites/default/files/maps/Commuter_Rail_Map.pdf")
  end
  def map_pdf_url(:ferry) do
    static_url(Site.Endpoint, "/sites/default/files/maps/Ferry_Map.pdf")
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
  def map_image_url(:subway) do
    static_url(Site.Endpoint, "/images/map_thumbnails/Rapid_Transit_Map.png")
  end
  def map_image_url(:bus) do
    static_url(Site.Endpoint, "/images/map_thumbnails/Full_System_Map.png")
  end
  def map_image_url(:commuter_rail) do
    static_url(Site.Endpoint, "/images/map_thumbnails/Commuter_Rail_Map.png")
  end
  def map_image_url(:ferry) do
    static_url(Site.Endpoint, "/images/map_thumbnails/Ferry_Map.png")
  end
  def map_image_url(_) do
    nil
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
  @spec map_stop_icon_path(Marker.size | nil, boolean) :: String.t
  def map_stop_icon_path(size, filled \\ false)
  def map_stop_icon_path(:mid, false), do: "000000-dot-mid"
  def map_stop_icon_path(:mid, true), do: "000000-dot-filled-mid"
  def map_stop_icon_path(_size, true), do: "000000-dot-filled"
  def map_stop_icon_path(_size, false), do: "000000-dot"
end

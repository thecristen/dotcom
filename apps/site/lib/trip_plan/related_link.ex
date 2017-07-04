defmodule Site.TripPlan.RelatedLink do
  @moduledoc """
  A link related to a particular itinerary.
  """
  @type t :: %__MODULE__{
    text: iodata,
    url: String.t,
    icon_name: icon_name
  }
  @type icon_name :: Routes.Route.gtfs_route_type | Routes.Route.subway_lines_type | nil

  defstruct [
    text: "",
    url: "",
    icon_name: nil
  ]

  @default_opts [route_by_id: &Routes.Repo.get/1]

  import Phoenix.HTML.Link, only: [link: 2]
  # Need a view in order to use the components. Ideally we'd have a separate
  # module, but that doesn't work at the moment.
  import Site.LayoutView, only: [svg_icon_with_circle: 1]
  import Site.Router.Helpers
  alias TripPlan.{Itinerary, Leg}
  alias Routes.Route

  @doc "Returns a new RelatedLink"
  @spec new(text, url, icon_name) :: t when text: iodata, url: String.t
  def new(text, url, icon_name \\ nil) when is_binary(url) and (is_binary(text) or is_list(text)) do
    %__MODULE__{
      text: text,
      url: url,
      icon_name: icon_name
    }
  end

  @doc "Returns the text of the link as a binary"
  @spec text(t) :: binary
  def text(%__MODULE__{text: text}) do
    IO.iodata_to_binary(text)
  end

  @doc "Returns the URL of the link"
  @spec url(t) :: String.t
  def url(%__MODULE__{url: url}) do
    url
  end

  @doc "Returns the HTML link for the RelatedLink"
  @spec as_html(t) :: Phoenix.HTML.Safe.t
  def as_html(%__MODULE__{} = rl) do
    link to: rl.url do
      [
        optional_icon(rl.icon_name),
        rl.text
      ]
    end
  end

  @doc "Builds a list of related links for an Itinerary"
  @spec links_for_itinerary(Itinerary.t, Keyword.t) :: [t]
  def links_for_itinerary(itinerary, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)
    route_by_id = Keyword.get(opts, :route_by_id)
    route_links = for {route_id, trip_id} <- Itinerary.route_trip_ids(itinerary) do
      route_id |> route_by_id.() |> route_link(trip_id, itinerary)
    end
    fare_links = for leg <- itinerary.legs,
      {:ok, route_id} <- [Leg.route_id(leg)],
      route = route_by_id.(route_id) do
        fare_link(route, leg)
    end
    |> Enum.uniq
    |> simplify_fare_text

    Enum.concat(route_links, fare_links)
  end

  defp optional_icon(nil), do: []
  defp optional_icon(icon_name) do
    svg_icon_with_circle(%Site.Components.Icons.SvgIconWithCircle{icon: icon_name, class: "icon-small"})
  end

  defp route_link(route, trip_id, itinerary) do
    icon_name = Route.icon_atom(route)
    base_text = if Route.type_atom(route) == :bus do
      ["Route ", route.name]
    else
      route.name
    end
    text = [base_text, " schedules"]
    date = Timex.format!(itinerary.start, "{ISOdate}")
    url = schedule_path(Site.Endpoint, :show, route, date: date, trip: trip_id)
    new(text, url, icon_name)
  end

  defp fare_link(route, leg) do
    type_atom = Route.type_atom(route)
    text = fare_link_text(type_atom)
    {fare_section, opts} = fare_link_url_opts(type_atom, leg)
    url = fare_path(Site.Endpoint, :show, fare_section, opts)
    new(["View ", text, " fare information"], url)
  end

  defp fare_link_text(:commuter_rail) do
    "commuter rail"
  end
  defp fare_link_text(:ferry) do
    "ferry"
  end
  defp fare_link_text(_) do
    "bus/subway"
  end

  defp fare_link_url_opts(type, leg) when type in [:commuter_rail, :ferry] do
    {type, origin: leg.from.stop_id, destination: leg.to.stop_id}
  end
  defp fare_link_url_opts(type, _leg) when type in [:bus, :subway] do
    {:bus_subway, []}
  end

  defp simplify_fare_text([fare_link]) do
    # if there's only one fare link, change the text to "View fare information"
    [%{fare_link | text: "View fare information"}]
  end
  defp simplify_fare_text(fare_links) do
    fare_links
  end
end

defimpl Phoenix.HTML.Safe, for: Site.TripPlan.RelatedLink do
  alias Site.TripPlan.RelatedLink

  def to_iodata(rl) do
    rl
    |> RelatedLink.as_html
    |> Phoenix.HTML.Safe.to_iodata
  end
end

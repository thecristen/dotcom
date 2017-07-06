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
  alias TripPlan.Itinerary
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
    route_links = for route_id <- Itinerary.route_ids(itinerary) do
      route_id |> route_by_id.() |> route_link
    end
    fare_links = for route_id <- Itinerary.route_ids(itinerary) do
      route_id |> route_by_id.() |> fare_link
    end
    [route_links, fare_links]
    |> Enum.concat
    |> Enum.uniq
  end

  defp optional_icon(nil), do: []
  defp optional_icon(icon_name) do
    svg_icon_with_circle(%Site.Components.Icons.SvgIconWithCircle{icon: icon_name, class: "icon-small"})
  end

  defp route_link(route) do
    icon_name = Route.icon_atom(route)
    base_text = if Route.type_atom(route) == :bus do
      ["Route ", route.name]
    else
      route.name
    end
    text = [base_text, " schedules"]
    url = schedule_path(Site.Endpoint, :show, route.id)
    new(text, url, icon_name)
  end

  defp fare_link(route) do
    text = "View fare information"
    fare_section = case Route.type_atom(route) do
                     :subway -> :bus_subway
                     :bus -> :bus_subway
                     other -> other
                   end
    url = fare_path(Site.Endpoint, :show, fare_section)
    new(text, url)
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

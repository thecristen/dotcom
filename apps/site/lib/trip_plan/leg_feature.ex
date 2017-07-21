defmodule Site.TripPlan.LegFeature do
  @moduledoc """
  A small icon representing a leg: shorthand for the mode of travel for that leg.
  """
  import Site.LayoutView, only: [svg_icon_with_circle: 1]
  import Site.ViewHelpers, only: [svg: 1]
  alias Site.Components.Icons.SvgIconWithCircle
  alias TripPlan.{Itinerary, Leg, TransitDetail, PersonalDetail}

  @type t :: Phoenix.HTML.Safe.t

  @default_opts [route_by_id: &Routes.Repo.get/1]

  @spec for_itinerary(Itinerary.t, Keyword.t) :: [t]
  def for_itinerary(itinerary, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)
    for leg <- itinerary do
      leg_feature(leg, opts)
    end
  end

  @doc "A small display representing the travel on a given Leg"
  @spec leg_feature(Leg.t, Keyword.t) :: t
  def leg_feature(%Leg{mode: %TransitDetail{} = mode}, opts) do
    route_by_id = Keyword.get(opts, :route_by_id)
    icon = mode.route_id
    |> route_by_id.()
    |> Routes.Route.icon_atom
    svg_icon_with_circle(%SvgIconWithCircle{icon: icon, class: "icon-small"})
  end
  def leg_feature(%Leg{mode: %PersonalDetail{}}, _) do
    svg("walk.svg")
  end
end

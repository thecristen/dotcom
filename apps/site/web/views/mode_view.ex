defmodule Site.ModeView do
  use Site.Web, :view

  def get_route_group(:bus = route_type, route_groups) do
    route_groups[route_type] |> Enum.filter(&Routes.Route.key_route?/1)
  end

  def get_route_group(:subway = route_type, route_groups) do
    route_groups[route_type] |> Enum.filter(&Routes.Route.key_route?/1)
  end

  def get_route_group(:commuter_rail = route_type, route_groups) do
    route_groups[route_type] |> Enum.sort_by(&(&1.name))
  end

  def get_route_group(route_type, route_groups), do: route_groups[route_type]

  @spec fares_note(String) :: Phoenix.HTML.Safe.t | String.t
  @doc "Returns a note describing fares for the given mode"
  def fares_note("Commuter Rail") do
    content_tag :p do
      "Commuter Rail fares are separated into ten zones based on your origin and destination. Fares can be bought as One Way, Round Trip, and Monthly Passes. Shown below are the ranges for each fare zone."
    end
  end
  def fares_note(_mode) do
      ""
  end
end

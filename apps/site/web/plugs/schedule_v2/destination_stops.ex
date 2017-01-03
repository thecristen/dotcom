defmodule Site.Plugs.ScheduleV2.DestinationStops do
  @moduledoc """

  Fetch unavailable origin/destination stops for the given route. If no
  origin is set then we don't know which destinations are unavailable yet,
  and only the last origin in @all_stops is excluded. If the route is the red
  line on the Ashmont or Braintree branches, exclude destinations on the
  other branch, and depending on the direction, either Ashmont/Braintree or
  Alewife are unavailable as origins.

  """

  @braintree_stops [
    "place-brntn",
    "place-qamnl",
    "place-qnctr",
    "place-wlsta",
    "place-nqncy"
  ]
  @ashmont_stops [
    "place-asmnl",
    "place-smmnl",
    "place-fldcr",
    "place-shmnl"
  ]

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{assigns: %{
                route: %{id: "Red"},
                direction_id: direction_id,
                origin: origin
             }} = conn, _) do

    conn
    |> assign(:excluded_origin_stops, excluded_red_origin_stops(direction_id))
    |> assign(:excluded_destination_stops, excluded_red_destination_stops(origin))
  end
  def call(%{assigns: %{all_stops: all_stops}} = conn, _) when all_stops != [] do
    conn
    |> assign(:excluded_origin_stops, [List.last(all_stops).id])
    |> assign(:excluded_destination_stops, [])
  end
  def call(conn, []) do
    conn
    |> assign(:excluded_origin_stops, [])
    |> assign(:excluded_destination_stops, [])
  end

  defp excluded_red_origin_stops(0) do
    ["place-brntn", "place-asmnl"]
  end
  defp excluded_red_origin_stops(1) do
    ["place-alfcl"]
  end

  defp excluded_red_destination_stops(origin) when origin in @braintree_stops do
    @ashmont_stops
  end
  defp excluded_red_destination_stops(origin) when origin in @ashmont_stops do
    @braintree_stops
  end
  defp excluded_red_destination_stops(_origin) do
    []
  end
end

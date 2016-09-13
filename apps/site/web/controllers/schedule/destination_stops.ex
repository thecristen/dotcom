defmodule Site.ScheduleController.DestinationStops do
  @moduledoc """
  Fetch applicable destination stops for the given route. If no origin is set then we don't need
  destinations yet. If the route is northbound on the red line coming from the Ashmont or Braintree
  branches, filter out stops on the opposite branch. For all other routes, the already assigned
  :all_stops is sufficient.
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
                all_stops: all_stops,
                direction_id: direction_id,
                origin: origin
             }} = conn, _) do
    northbound = direction_id == 1
    filtered_stops = cond do
      northbound and origin in @braintree_stops ->
        Enum.reject(all_stops, &(&1.id in @ashmont_stops))
      northbound and origin in @ashmont_stops ->
        Enum.reject(all_stops, &(&1.id in @braintree_stops))
      true ->
        all_stops
    end

    conn
    |> assign(:destination_stops, filtered_stops)
  end
  def call(%{assigns: %{all_stops: all_stops}} = conn, _) do
    conn
    |> assign(:destination_stops, all_stops)
  end
  def call(conn, []) do
    conn
  end
end

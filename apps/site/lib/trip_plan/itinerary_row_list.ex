defmodule Site.TripPlan.ItineraryRowList do

  @moduledoc """
  A data structure describing a list of ItineraryRows and
  the final destination of an itinerary
  """
  alias Site.TripPlan.ItineraryRow
  alias TripPlan.Itinerary

  @typep destination :: {String.t, String.t, DateTime.t}

  defstruct [
    rows: [],
    destination: nil
  ]

  @type t :: %__MODULE__{
    rows: [ItineraryRow.t],
    destination: destination
  }

  @doc  """
  Builds a ItineraryRowList from the given itinerary
  """
  @spec from_itinerary(Itinerary.t, Keyword.t) :: t
  def from_itinerary(%Itinerary{legs: legs}, opts) do
    %__MODULE__{rows: get_rows(legs, opts), destination: get_destination(legs)}
  end

  @spec get_rows([TripPlan.Leg.t], Keyword.t) :: [ItineraryRow.t]
  defp get_rows(legs, opts) do
    legs
    |> Enum.map(&ItineraryRow.from_leg(&1, opts))
    |> arrival_times(legs)
  end

  @spec arrival_times([ItineraryRow.t], [TripPlan.Leg.t]) :: [ItineraryRow.t]
  defp arrival_times(itinerary_rows, legs) do
    itinerary_rows
    |> Enum.zip([nil | legs])
    |> Enum.map(&do_arrival_times/1)
  end

  @spec do_arrival_times({ItineraryRow.t, TripPlan.Leg.t | nil}) :: ItineraryRow.t
  defp do_arrival_times({itinerary_row, nil}) do
    %{itinerary_row | arrival: nil}
  end
  defp do_arrival_times({itinerary_row, leg}) do
    %{itinerary_row | arrival: leg.stop}
  end

  @spec get_destination([TripPlan.Leg.t]) :: destination
  defp get_destination(legs) do
    last_leg = List.last(legs)
    {name, stop_id} = last_leg |> Map.get(:to) |> ItineraryRow.name_from_position()
    {name, stop_id, last_leg.stop}
  end
end

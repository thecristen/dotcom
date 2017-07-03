defmodule Site.TripPlan.ItineraryRowList do
  alias Site.TripPlan.ItineraryRow
  alias TripPlan.{Itinerary, Leg}

  defstruct [
    rows: [],
    destination: nil
  ]

  @type t :: %__MODULE__{
    rows: [ItineraryRow.t],
    destination: {String.t, String.t, DateTime.t}
  }

  def from_itinerary(%Itinerary{legs: legs}) do
    %__MODULE__{rows: get_rows(legs), destination: get_destination(List.last(legs))}
  end

  defp get_rows(legs) do
    legs
    |> Enum.map(&ItineraryRow.from_leg/1)
    |> arrival_times(legs)
  end

  defp arrival_times(itinerary_rows, legs) do
    itinerary_rows
    |> Enum.zip([nil | legs])
    |> Enum.map(&do_arrival_times/1)
  end

  defp do_arrival_times({itinerary_row, nil}) do
    %{itinerary_row | arrival: nil}
  end
  defp do_arrival_times({itinerary_row, leg}) do
    %{itinerary_row | arrival: leg.stop}
  end

  defp get_destination(leg) do
    {name, stop_id} = ItineraryRow.name_from_position(leg.to)
    {name, stop_id, leg.stop}
  end
end

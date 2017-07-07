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
  def from_itinerary(%Itinerary{legs: legs} = itinerary, opts) do
    %__MODULE__{rows: get_rows(itinerary, opts), destination: get_destination(legs)}
  end

  @spec get_rows(Itinerary.t, Keyword.t) :: [ItineraryRow.t]
  defp get_rows(itinerary, opts) do
    [nil]
    |> Enum.concat(itinerary)
    |> Enum.zip(itinerary)
    |> Enum.map(fn {before, current} -> ItineraryRow.from_legs(current, before, opts) end)
  end

  @spec get_destination([TripPlan.Leg.t]) :: destination
  defp get_destination(legs) do
    last_leg = List.last(legs)
    {name, stop_id} = last_leg |> Map.get(:to) |> ItineraryRow.name_from_position()
    {name, stop_id, last_leg.stop}
  end
end

defimpl Enumerable, for: Site.TripPlan.ItineraryRowList do
  def count(_itinerary_row_list) do
    {:error, __MODULE__}
  end

  def member?(_itinerary_row_list, %Site.TripPlan.ItineraryRow{}) do
    {:error, __MODULE__}
  end
  def member?(_itinerary_row_list, _other) do
    {:ok, false}
  end

  def reduce(%{rows: rows}, acc, fun) do
    Enumerable.reduce(rows, acc, fun)
  end
end

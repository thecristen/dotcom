defmodule Fares.RetailLocations do
  alias Stops.Stop
  defmodule Location do
    defstruct [:agent,
               :city,
               :dates_sold,
               :hours_of_operation,
               :latitude,
               :longitude,
               :location,
               :method_of_payment,
               :name,
               :telephone,
               :type_of_passes_on_sale2007
             ]

    @type t :: %__MODULE__{ agent: String.t, city: String.t, dates_sold: String.t, hours_of_operation: String.t,
                            latitude: float, longitude: float, method_of_payment: String.t, name: String.t,
                            telephone: String.t, type_of_passes_on_sale2007: String.t}

    defimpl Stops.Position do
      def latitude(%@for{latitude: latitude}), do: latitude
      def longitude(%@for{longitude: longitude}), do: longitude
    end
  end

  @locations __MODULE__.Data.get

  @doc """
    Takes a latitude and longitude and returns the three closest retail locations for purchasing fares.
  """
  @spec get_nearby(Stop.t) :: [Location.t]
  def get_nearby(stop) do
    @locations
    |> Enum.map(&{&1, get_distance(&1, stop)})
    |> Enum.sort(&sort_by_closest/2)
    |> Enum.take(4)
  end

  @spec get_distance(Location.t, Stop.t) :: float
  defp get_distance(%Location{latitude: lat, longitude: lng}, stop) do
    %{latitude: lat, longitude: lng}
    |> Stops.Distance.haversine(stop)
  end

  @spec sort_by_closest({Location.t, float}, {Location.t, float}) :: boolean
  defp sort_by_closest({_, prev}, {_,next}), do: prev <= next
end

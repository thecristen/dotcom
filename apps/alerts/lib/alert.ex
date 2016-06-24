defmodule Alerts.Alert do
  defstruct [
    :id, :header, :informed_entity, :active_period, :effect_name, :severity, :lifecycle, :updated_at, :description
  ]
end

defmodule Alerts.InformedEntity do
  defstruct [:route_type, :route, :stop, :trip]

  alias __MODULE__, as: IE

  @spec put(%IE{}, :route|:route_type|:stop|:trip, any) :: %IE{}
  def put(entity, :route_type, value) do
    %Alerts.InformedEntity{entity | route_type: value}
  end
  def put(entity, :route, value) do
    %Alerts.InformedEntity{entity | route: value}
  end
  def put(entity, :stop, value) do
    %Alerts.InformedEntity{entity | stop: value}
  end
  def put(entity, :trip, value) do
    %Alerts.InformedEntity{entity | trip: value}
  end

  @doc """

  Returns true if the two InformedEntities match.

  If a route/route_type/stop is specified (non-nil), it needs to equal the other.
  Otherwise the nil can match any value in the other InformedEntity.

  """
  @spec match?(%IE{}, %IE{}) :: boolean
  def match?(%IE{} = first, %IE{} = second) do
    do_match?(first, second) || do_match?(second, first)
  end

  def do_match?(first, second) do
    {map1, map2} = {Map.from_struct(first), Map.from_struct(second)}

    map1
    |> Enum.all?(fn
      ({key, value}) -> map2[key] == nil or map2[key] == value
    end)
  end
end

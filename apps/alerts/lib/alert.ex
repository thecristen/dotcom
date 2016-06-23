defmodule Alerts.Alert do
  defstruct [
    :id, :header, :informed_entity, :active_period, :effect_name, :severity, :lifecycle, :updated_at, :description
  ]
end

defmodule Alerts.InformedEntity do
  defstruct [:route_type, :route, :stop]

  alias __MODULE__, as: IE

  @spec put(%IE{}, :route|:route_type|:stop, any) :: %IE{}
  def put(entity, :route_type, value) do
    %Alerts.InformedEntity{entity | route_type: value}
  end
  def put(entity, :route, value) do
    %Alerts.InformedEntity{entity | route: value}
  end
  def put(entity, :stop, value) do
    %Alerts.InformedEntity{entity | stop: value}
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

  defp do_match?(
        %IE{route_type: route_type, route: route, stop: stop},
        %IE{route_type: route_type, route: route, stop: stop})
  when is_integer(route_type) and is_binary(route) and is_binary(stop) do
    true
  end
  defp do_match?(
        %IE{route_type: route_type, route: route, stop: nil},
        %IE{route_type: route_type, route: route, stop: _})
  when is_integer(route_type) and is_binary(route) do
    true
  end
  defp do_match?(
        %IE{route_type: route_type, route: nil, stop: stop},
        %IE{route_type: route_type, route: _, stop: stop})
  when is_integer(route_type) and is_binary(stop) do
    true
  end
  defp do_match?(
        %IE{route_type: nil, route: route, stop: stop},
        %IE{route_type: _, route: route, stop: stop})
  when is_binary(route) and is_binary(stop) do
    true
  end
  defp do_match?(
        %IE{route_type: route_type, route: nil, stop: nil},
        %IE{route_type: route_type, route: _, stop: _})
  when is_integer(route_type) do
    true
  end
  defp do_match?(
        %IE{route_type: nil, route: route, stop: nil},
        %IE{route_type: _, route: route, stop: _})
  when is_binary(route) do
    true
  end
  defp do_match?(
        %IE{route_type: nil, route: nil, stop: stop},
        %IE{route_type: _, route: _, stop: stop})
  when is_binary(stop) do
    true
  end
  defp do_match?(_, _) do
    false
  end
end

defmodule Routes.Group do
  @moduledoc """

  Groups a list of Route structures into a map based on their type: Commuter Rail, Bus, or Subway

  """

  @spec group([Route.Route]) :: %{String: Routes.Route}
  def group(routes) do
    routes
    |> Enum.reverse
    |> Enum.reduce(%{}, &reducer/2)
  end

  defp reducer(route, acc) do
    acc_key = key(route)

    acc
    |> Dict.update(acc_key, [route], fn(value) -> [route|value] end)
  end

  defp key(%{type: 0}) do
    :subway
  end
  defp key(%{type: 1}) do
    :subway
  end
  defp key(%{type: 2}) do
    :commuter_rail
  end
  defp key(%{type: 3}) do
    :bus
  end
  defp key(%{type: _}) do
    :other
  end

end

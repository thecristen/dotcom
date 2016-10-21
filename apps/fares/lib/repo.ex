defmodule Fares.Repo do
  @fares Fares.FareInfo.fare_info

  alias Fares.Fare

  @spec all() :: [Fare.t]
  @spec all(Keyword.t) :: [Fare.t]
  def all() do
    @fares
  end
  def all(opts) when is_list(opts) do
    all
    |> filter(opts)
  end

  @spec filter([Fare.t], Dict.t) :: [Fare.t]
  def filter(fares, opts) do
    fares
    |> filter_all(Map.new(opts))
  end

  @spec filter_all([Fare.t], %{}) :: [Fare.t]
  defp filter_all(fares, opts) do
    Enum.filter(fares, fn fare -> match?(^opts, Map.take(fare, Map.keys(opts))) end)
  end
end

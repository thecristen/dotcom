defmodule Site.Validation do
  @moduledoc """
  This library is helpful for checking a map of params against a list of validation functions.

  Validation functions must:
  - return {:ok, any} if the check past
  - return {:error, String.t} if the check fails
  - take only one argument which is a map containing all the data fields to be validated

  if the second entry in the success tuple is a map, it's will be merged with params and it's output passed as input
  to subsequent validation functions.
  """

  @spec validate([fun], map) :: []
  def validate(validators, params) do
    validators
    |> Enum.reduce({MapSet.new, params}, fn(validator, {errors, params}) ->
      case validator.(params) do
        {:ok, %{} = output} -> {errors, Map.merge(params, output)}
        {:ok, _} -> {errors, params}
        {:error, output} -> {MapSet.put(errors, output), params}
      end
    end)
    |> elem(0)
    |> MapSet.to_list()
  end
end

defmodule Site.Validation do
  @moduledoc """
  Helper functions for performing data validation.
  """

  @doc """
  Takes a list of functions and a map of parameters.
  Returns a list containing the names of fields where validation errors occurred.
  Expects validation functions to return :ok or String.t
  """
  @spec validate([fun], map) :: []
  def validate(validators, params) do
    validators
    |> Enum.reduce(MapSet.new, fn (f, errors_map_set) ->
      case f.(params) do
        :ok -> errors_map_set
        error -> MapSet.put errors_map_set, error
      end
    end)
    |> MapSet.to_list()
  end

  @doc """
  Takes a map with string keys of field names associates to a validation function.
  Returns a map containing the field names associated to field errors, or and empty map.
  Expects validation functions to return :ok or String.t
  """
  @spec validate_by_field(map, map) :: map
  def validate_by_field(validations, params) do
    validations
    |> Enum.reduce(%{}, fn({field, validator}, errors_map) ->
      error = validator.(params)
      case {error, is_binary(error)} do
        {:ok, _} -> errors_map
        {_, true} -> Map.merge(errors_map, %{field => error})
        {_, _} -> Map.merge(errors_map, %{field => "error"})
      end
    end)
  end
end

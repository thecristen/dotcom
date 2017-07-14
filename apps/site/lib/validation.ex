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
    |> Enum.reduce(MapSet.new, fn (f, acc) ->
      case f.(params) do
        :ok -> acc
        field -> MapSet.put acc, field
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
    |> Enum.reduce(%{}, fn({field, validator}, acc) ->
      error = validator.(params)
      case {error, is_binary(error)} do
        {:ok, _} -> acc
        {_, true} -> Map.merge(acc, %{field => error})
        {_, _} -> Map.merge(acc, %{field => "error"})
      end
    end)
  end
end

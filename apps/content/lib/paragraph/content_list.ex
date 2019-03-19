defmodule Content.Paragraph.ContentList do
  @moduledoc """
  A content list paragraph (optionally including a header) from the CMS.
  This paragraph provides a formula for retreiving a dynamic list of
  content items from the CMS via the `/cms/teasers` API endpoint.
  """
  import Content.Helpers, only: [field_value: 2, int_or_string_to_int: 1]
  import Content.Paragraph, only: [parse_header: 1]

  alias Content.{Paragraph.ColumnMultiHeader, Repo, Teaser}

  defstruct header: nil,
            ingredients: %{},
            recipe: []

  @type t :: %__MODULE__{
          header: ColumnMultiHeader.t() | nil,
          ingredients: map(),
          recipe: Keyword.t()
        }

  @spec from_api(map) :: t
  def from_api(data) do
    terms =
      data
      |> Map.get("field_terms", [])
      |> Enum.map(& &1["target_id"])
      |> Enum.reject(&is_nil(&1))

    ingredients = %{
      terms: terms,
      term_depth: field_value(data, "field_term_depth"),
      items_per_page: field_value(data, "field_number_of_items"),
      type: field_value(data, "field_content_type"),
      type_op: field_value(data, "field_type_logic"),
      promoted: field_value(data, "field_promoted"),
      sticky: field_value(data, "field_sticky"),
      relationship: field_value(data, "field_relationship"),
      except: field_value(data, "field_content_logic"),
      content_id: field_value(data, "field_content_reference"),
      host_id: data |> field_value("parent_id") |> int_or_string_to_int(),
      date: field_value(data, "field_date"),
      date_op: field_value(data, "field_date_logic"),
      sort_by: field_value(data, "field_sorting"),
      sort_order: field_value(data, "field_sorting_logic")
    }

    recipe = combine(ingredients)

    %__MODULE__{
      header: parse_header(data),
      ingredients: ingredients,
      recipe: recipe
    }
  end

  @spec get_teasers_async(Keyword.t()) :: (() -> [Teaser.t()])
  def get_teasers_async(opts) do
    fn -> Repo.teasers(opts) end
  end

  # Some ingredients need to be pre-processed/merged before using
  # as CMS API-compatible path arguments or query parameters.
  @spec combine(map) :: Keyword.t()
  # Drop default value for items_per_page (default for the CMS API)
  defp combine(%{items_per_page: 5} = ingredients) do
    ingredients
    |> Map.drop([:items_per_page])
    |> combine()
  end

  # If no relationship data is found, discard all related data
  defp combine(%{relationship: nil, except: nil} = ingredients) do
    ingredients
    |> Map.drop([:except, :relationship, :host_id, :content_id])
    |> combine()
  end

  # If author has selected "except," update relationship type
  defp combine(%{relationship: nil} = ingredients) do
    ingredients
    |> Map.put(:relationship, "except")
    |> combine()
  end

  # If relating by host page, discard content ID and update relationship type
  defp combine(%{relationship: "host", host_id: id} = ingredients) do
    ingredients
    |> Map.drop([:host_id, :content_id])
    |> Map.put(:relationship, "related_to")
    |> Map.put(:id, id)
    |> combine()
  end

  # If a specific content ID is present, use that and discard the host page ID
  defp combine(%{content_id: id, host_id: _} = ingredients) do
    ingredients
    |> Map.drop([:host_id, :content_id])
    |> Map.put(:id, id)
    |> combine()
  end

  # Compose the API query param for the relationship using final ID
  defp combine(%{relationship: relationship, id: id} = ingredients) do
    ingredients
    |> Map.drop([:except, :relationship, :id])
    |> Map.put(String.to_atom(relationship), id)
    |> combine()
  end

  # If no terms are found, discard term and depth data
  defp combine(%{terms: []} = ingredients) do
    ingredients
    |> Map.drop([:terms, :term_depth])
    |> combine()
  end

  # If the default term depth is found, discard depth and compose arguments
  defp combine(%{terms: terms, term_depth: 4} = ingredients) do
    ingredients
    |> Map.drop([:terms, :term_depth])
    |> Map.put(:args, terms)
    |> combine()
  end

  # If we are using a non-standard depth, all arguments must be set if terms are present
  defp combine(%{terms: terms, term_depth: depth} = ingredients) do
    args_with_depth =
      case terms do
        [a] -> [a, "any", depth]
        [a, b] -> [a, b, depth]
      end

    ingredients
    |> Map.drop([:terms, :term_depth])
    |> Map.put(:args, args_with_depth)
    |> combine()
  end

  # Discard date information if no date operator has been set
  defp combine(%{date: _date, date_op: nil} = ingredients) do
    ingredients
    |> Map.drop([:date, :date_op])
    |> combine()
  end

  # Use relative time if date operator is specified without specific date
  defp combine(%{date: nil, date_op: operator} = ingredients) when is_binary(operator) do
    ingredients
    |> Map.put(:date, "now")
    |> combine()
  end

  # Ingredients are ready to bake into opts for endpoint call. Discard
  # all nil values and converts remaining ingredients to a list
  defp combine(ingredients) do
    Enum.reject(ingredients, fn {_k, v} -> is_nil(v) end)
  end
end

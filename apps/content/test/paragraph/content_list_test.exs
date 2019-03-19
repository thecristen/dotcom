defmodule Content.Paragraph.ContentListTest do
  @moduledoc """
  Tests struct-specific construction logic. Helper functions in this file
  build minimum-viable CMS API response JSON data from the CMS field name
  minus the "field_" prefix, followed by a typical value one would find.
  """

  use ExUnit.Case, async: true

  alias Content.Paragraph.ContentList

  describe "from_api/1" do
    test "Drops default value for items_per_page" do
      opts = cms_map(number_of_items: 5)

      assert opts == []
    end

    test "If no relationship data is found, discard all related data" do
      opts =
        cms_map(
          relationship: nil,
          except: nil,
          parent_id: 5678
        )

      assert opts == []
    end

    test "If author has selected 'except,' update relationship type" do
      opts =
        cms_map(
          relationship: nil,
          content_reference: 1234,
          content_logic: "except"
        )

      assert opts == [except: 1234]
    end

    test "If relating by host page, discard content ID and update relationship type" do
      opts =
        cms_map(
          relationship: "host",
          content_reference: 1234,
          parent_id: 5678
        )

      assert opts == [related_to: 5678]
    end

    test "If a specific content ID is present, use that and discard the host page ID" do
      opts =
        cms_map(
          relationship: "related_to",
          content_reference: 1234,
          parent_id: 5678
        )

      assert opts == [related_to: 1234]
    end

    test "If no terms are found, discard term and depth data" do
      opts =
        cms_map(
          terms: nil,
          term_depth: 4
        )

      assert opts == []
    end

    test "If the default term depth is found, discard depth and compose arguments" do
      opts =
        cms_map(
          terms: [123, 321],
          term_depth: 4
        )

      assert opts == [args: [123, 321]]
    end

    test "If we are using a non-standard depth, all arguments must be set if terms are present" do
      no_terms = cms_map(terms: nil, term_depth: 3)
      one_term = cms_map(terms: [123], term_depth: 3)
      two_terms = cms_map(terms: [123, 321], term_depth: 3)

      assert no_terms == []
      assert one_term == [args: [123, "any", 3]]
      assert two_terms == [args: [123, 321, 3]]
    end
  end

  test "Discard date information if no date operator has been set" do
    opts =
      cms_map(
        date: "2019-03-14",
        date_logic: nil
      )

    assert opts == []
  end

  test "Use relative time if date operator is specified without specific date" do
    opts =
      cms_map(
        date: nil,
        date_logic: ">="
      )

    assert opts == [date: "now", date_op: ">="]
  end

  test "Discards all nil values" do
    opts =
      cms_map(
        terms: nil,
        term_depth: 4,
        number_of_items: 5,
        content_type: "event",
        type_logic: nil,
        promoted: nil,
        sticky: nil,
        relationship: nil,
        content_logic: nil,
        content_reference: nil,
        parent_id: 5678,
        date: nil,
        date_logic: nil,
        sorting: nil,
        sorting_logic: nil
      )

    assert opts == [type: "event"]
  end

  defp cms_map(fields) do
    fields
    |> Enum.into(%{}, &cms_field/1)
    |> ContentList.from_api()
    |> Map.get(:recipe)
  end

  defp cms_field({k, nil}) do
    {"field_#{k}", []}
  end

  defp cms_field({:content_reference = k, v}) do
    {"field_#{k}", [%{"target_id" => v}]}
  end

  defp cms_field({:terms = k, terms}) do
    {"field_#{k}", Enum.map(terms, &%{"target_id" => &1})}
  end

  defp cms_field({:parent_id = k, v}) do
    {"#{k}", [%{"value" => v}]}
  end

  defp cms_field({k, v}) do
    {"field_#{k}", [%{"value" => v}]}
  end
end

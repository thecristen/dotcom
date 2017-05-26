defmodule Content.CmsMigration.NewsMigratorTest do
  use ExUnit.Case
  import Content.FixtureHelpers
  alias Content.CmsMigration.NewsMigrator

  @filename "cms_migration/valid_news_entry/news_entry.json"

  describe "migrate/2" do
    test "creates a news entry in the CMS" do
      news_entry_data = fixture(@filename)
      assert {:ok, :created} = NewsMigrator.migrate(news_entry_data)
    end

    test "given the news entry already exists in the CMS, updates the entry" do
      previously_migrated_news_entry =
        @filename
        |> fixture
        |> Map.put("id", "1234")

      assert {:ok, :updated} = NewsMigrator.migrate(previously_migrated_news_entry)
    end

    test "when the news entry fails to create" do
      invalid_news_entry =
        @filename
        |> fixture
        |> Map.put("information", "fails-to-create")

      assert {:error, %{status_code: 422}} = NewsMigrator.migrate(invalid_news_entry)
    end

    test "when the news entry fails to update" do
      id_for_existing_record = "1234"

      invalid_news_entry =
        @filename
        |> fixture
        |> Map.put("information", "fails-to-update")
        |> Map.put("id", id_for_existing_record)

      assert {:error, %{status_code: 422}} = NewsMigrator.migrate(invalid_news_entry)
    end

    test "when querying for an existing record returns more than one record" do
      record_with_non_unique_migration_id =
        @filename
        |> fixture
        |> Map.put("id", "multiple-records")

      expected_error_message = "multiple records were found when querying by migration_id: multiple-records."

      assert_raise Content.MigrationError, expected_error_message, fn ->
        NewsMigrator.migrate(record_with_non_unique_migration_id)
      end
    end
  end
end

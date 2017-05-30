defmodule Content.CmsMigration.NewsMigrator do
  alias Content.MigrationError
  alias Content.CmsMigration.NewsEntryPayload

  @spec migrate(map) :: {:ok, :created} | {:ok, :updated} | {:error, map}
  def migrate(news_entry_data) do
    migration_id = Map.fetch!(news_entry_data, "id")

    news_entry_data
    |> NewsEntryPayload.build()
    |> migrate_news_entry(migration_id)
  end

  defp migrate_news_entry(news_entry, migration_id) do
    encoded_news_entry = Poison.encode!(news_entry)

    if news_entry_id = check_for_existing_news_entry!(migration_id) do
      update_news_entry(news_entry_id, encoded_news_entry)
    else
      create_news_entry(encoded_news_entry)
    end
  end

  defp check_for_existing_news_entry!(migration_id) do
    case Content.Repo.news(migration_id: migration_id) do
      [%Content.NewsEntry{id: id, migration_id: ^migration_id}] -> id
      [] -> nil
      _multiple_records -> raise MigrationError,
        message: "multiple records were found when querying by migration_id: #{migration_id}."
    end
  end

  @spec update_news_entry(integer, String.t) :: {:ok, :updated} | {:error, map}
  defp update_news_entry(id, body) do
    with {:ok, _news_entry} <- Content.Repo.update_news_entry(id, body) do
      {:ok, :updated}
    end
  end

  @spec create_news_entry(String.t) :: {:ok, :created} | {:error, map}
  defp create_news_entry(body) do
    with {:ok, _news_entry} <- Content.Repo.create_news_entry(body) do
      {:ok, :created}
    end
  end
end

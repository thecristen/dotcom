defmodule Content.MetaData do
  def for("news_entry") do
    %{
      recent_news: fetch_recent_news()
    }
  end
  def for(_), do: %{}

  def fetch_recent_news do
    case Content.Repo.page("/recent-news") do
      {:ok, recent_news} -> recent_news
      {:error, _error} -> []
    end
  end
end

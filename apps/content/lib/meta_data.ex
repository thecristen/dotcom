defmodule Content.MetaData do
  def for_news_entry do
    %{
      recent_news: fetch_recent_news()
    }
  end

  def fetch_recent_news do
    Content.Repo.recent_news
  end
end

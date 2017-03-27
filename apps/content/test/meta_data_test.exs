defmodule Content.MetaDataTest do
  use ExUnit.Case, async: false

  test "for_news_entry returns map of news entries" do
    %{recent_news: [%Content.NewsEntry{} = news_entry | _]} = Content.MetaData.for_news_entry
    assert news_entry.title =~ "FMCB approves Blue Hill"
  end
end

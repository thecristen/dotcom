defmodule Content.Factory do
  def event_factory do
    data = Content.CMS.Static.events_response() |> List.first
    Content.Event.from_api(data)
  end

  def news_entry_factory(options \\ %{}) do
    Content.CMS.Static.news_response()
    |> List.first
    |> Content.NewsEntry.from_api()
    |> Map.merge(options)
  end
end

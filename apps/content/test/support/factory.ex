defmodule Content.Factory do
  def event_factory do
    data = Content.CMS.Static.events_response() |> List.first
    Content.Event.from_api(data)
  end
end

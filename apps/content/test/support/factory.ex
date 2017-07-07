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

  def person_factory(options \\ %{}) do
    person_json = person_from_people_grid_paragraph()

    person_json
    |> Content.Person.from_api()
    |> Map.merge(options)
  end

  defp person_from_people_grid_paragraph do
    Content.CMS.Static.all_paragraphs_response()
    |> Map.get("field_paragraphs")
    |> Enum.find(& match?(%{"type" => [%{"target_id" => "people_grid"}]}, &1))
    |> Map.get("field_people")
    |> List.first()
  end
end

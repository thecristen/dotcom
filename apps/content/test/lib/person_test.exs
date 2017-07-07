defmodule Content.PersonTest do
  use ExUnit.Case, async: true

  setup do
    %{api_person: person_from_people_grid_paragraph()}
  end

  describe "from_api/1" do
    test "parses the api response and returns a struct", %{api_person: api_person} do
      bio = Phoenix.HTML.raw("<p>Likes bacon and eggs.</p>")

      assert %Content.Person{
        id: 1,
        bio: ^bio,
        name: "Ron Swanson",
        position: "Director of Pawnee Parks and Recreation Department",
        profile_image: %Content.Field.Image{}
      } = Content.Person.from_api(api_person)
    end
  end

  defp person_from_people_grid_paragraph do
    Content.CMS.Static.all_paragraphs_response()
    |> Map.get("field_paragraphs")
    |> Enum.find(& match?(%{"type" => [%{"target_id" => "people_grid"}]}, &1))
    |> Map.get("field_people")
    |> List.first()
  end
end

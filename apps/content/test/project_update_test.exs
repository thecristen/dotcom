defmodule Content.ProjectUpdateTest do
  use ExUnit.Case
  import Content.CMSTestHelpers, only: [update_api_response_whole_field: 3]

  setup do
    %{api_data: Content.CMS.Static.project_update_response()}
  end

  describe "from_api/1" do
    test "maps the project update api data to a struct", %{api_data: api_data} do
      assert %Content.ProjectUpdate{
        id: id,
        body: body,
        photo_gallery: [],
        posted_on: posted_on,
        project_id: project_id,
        teaser: teaser,
        title: title
      } = Content.ProjectUpdate.from_api(api_data)

      assert id == 123
      assert Phoenix.HTML.safe_to_string(body) == "<p>body</p>"
      assert posted_on == ~D[2017-08-24]
      assert project_id == 2669
      assert teaser == "teaser"
      assert title == "Project Update Title"
    end

    test "when photo gallery images are provided", %{api_data: api_data} do
      project_update_data =
        api_data
        |> update_api_response_whole_field("field_photo_gallery", image_api_data())

      project_update = Content.ProjectUpdate.from_api(project_update_data)

      assert [%Content.Field.Image{}] = project_update.photo_gallery
    end
  end

  defp image_api_data do
    [%{
      "alt" => "image alt",
      "url" => "http://example.com/files/train.jpeg"
    }]
  end
end

defmodule Content.ProjectTest do
  use ExUnit.Case
  import Content.CMSTestHelpers, only: [
    update_api_response: 3,
    update_api_response_whole_field: 3
  ]

  setup do
    %{api_data: Content.CMS.Static.projects_response() |> List.first}
  end

  describe "from_api/1" do
    test "maps project api data to a struct", %{api_data: api_data} do
      assert %Content.Project{
        id: id,
        body: body,
        contact_information: contact_information,
        end_year: end_year,
        featured: featured,
        featured_image: nil,
        files: [],
        media_email: media_email,
        media_phone: media_phone,
        photo_gallery: [],
        start_year: start_year,
        status: status,
        teaser: teaser,
        title: title,
        updated_on: updated_on
      } = Content.Project.from_api(api_data)

      assert id == 1
      assert Phoenix.HTML.safe_to_string(body) == "<p>body</p>"
      assert contact_information == "Contact this person"
      assert end_year == "2018"
      assert featured == false
      assert media_email == "foo@example.com"
      assert media_phone == "(123) 456-7891"
      assert start_year == "2017"
      assert status == "Procurement"
      assert teaser == "teaser"
      assert title == "title"
      assert updated_on == ~D[2017-08-24]
    end

    test "when files are provided", %{api_data: api_data} do
      project_data =
        api_data
        |> update_api_response_whole_field("field_files", file_api_data())

      project = Content.Project.from_api(project_data)

      assert [%Content.Field.File{}] = project.files
    end

    test "when a project is featured", %{api_data: api_data} do
      project_data =
        api_data
        |> update_api_response_whole_field("field_featured_image", image_api_data())
        |> update_api_response("field_featured", true)

      project = Content.Project.from_api(project_data)

      assert %Content.Field.Image{} = project.featured_image
      assert project.featured == true
    end

    test "when photo gallery images are provided", %{api_data: api_data} do
      project_data =
        api_data
        |> update_api_response_whole_field("field_photo_gallery", image_api_data())

      project = Content.Project.from_api(project_data)

      assert [%Content.Field.Image{}] = project.photo_gallery
    end
  end

  defp image_api_data do
    [%{
      "alt" => "image alt",
      "url" => "http://example.com/files/train.jpeg"
    }]
  end

  defp file_api_data do
    [%{
      "description" => "important file",
      "url" => "http://example.com/files/important.txt",
      "mime_type" => "text/plain"
    }]
  end
end

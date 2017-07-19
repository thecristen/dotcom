defmodule Content.ProjectUpdateTest do
  use ExUnit.Case

  import Content.CMSTestHelpers, only: [update_api_response_whole_field: 3]

  setup do
    %{api_page: Content.CMS.Static.project_update_response()}
  end

  describe "from_api/1" do
    test "parses the api response when empty associations", %{api_page: api_page} do
      api_page = api_page
      |> update_api_response_whole_field("field_featured_image", [])
      |> update_api_response_whole_field("field_photo_gallery", [])
      |> update_api_response_whole_field("field_downloads", [])

      assert %Content.ProjectUpdate{
        id: id,
        body: body,
        title: title,
        featured_image: nil,
        photo_gallery: [],
        updated_at: updated_at,
        status: status,
        downloads: []
      } = Content.ProjectUpdate.from_api(api_page)

      assert id == 3
      assert Phoenix.HTML.safe_to_string(body) =~ "<p>Value Engineering (VE)"
      assert title == "Government Center Construction"
      assert DateTime.to_unix(updated_at) == 1_489_597_382
      assert status == "Construction"
    end

    test "rewrites the featured image, photo_gallery, and downloads URLs", %{api_page: api_page} do
      original_drupal_config = Application.get_env(:content, :drupal)
      Application.put_env(:content, :drupal, %{root: "http://drupalhost.com", static_path: "/static/"})

      api_page = api_page
      |> update_api_response_whole_field("field_featured_image",
        [%{"alt" => "alt text", "url" => "http://drupalhost.com/static/my_image.png"}])
      |> update_api_response_whole_field("field_photo_gallery",
        [%{"alt" => "gallery alt text", "url" => "http://drupalhost.com/static/photo1.png"}])
      |> update_api_response_whole_field("field_downloads",
        [%{"description" => "this is the description", "target_type" => "file", "url" => "http://drupalhost.com/static/download1.pdf", "mime_type" => "application/pdf"}])

      assert %Content.ProjectUpdate{
        featured_image: %Content.Field.Image{alt: featured_alt, url: featured_url},
        photo_gallery: [%Content.Field.Image{alt: gallery_alt, url: gallery_url}],
        downloads: [%Content.Field.File{description: description, type: type, url: download_url}]
      } = Content.ProjectUpdate.from_api(api_page)

      assert featured_alt == "alt text"
      assert featured_url == Content.Config.apply(:static, ["/static/my_image.png"])
      assert gallery_alt == "gallery alt text"
      assert gallery_url == Content.Config.apply(:static, ["/static/photo1.png"])
      assert description == "this is the description"
      assert type == "application/pdf"
      assert download_url == Content.Config.apply(:static, ["/static/download1.pdf"])

      Application.put_env(:content, :drupal, original_drupal_config)
    end
  end
end

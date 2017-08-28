defmodule Content.Field.ImageTest do
  use ExUnit.Case, async: true
  import Content.ImageHelpers, only: [site_app_domain: 0]

  describe "from_api/1" do
    test "maps image api data to a struct" do
      image_data = %{
        "target_id" => 1,
        "alt" => "Purple Train",
        "title" => "",
        "width" => "800",
        "height" => "600",
        "target_type" => "file",
        "target_uuid" => "universal-unique-identifier",
        "url" => "http://example.com/files/purple-train.jpeg",
        "mime_type" => "image/jpeg"
      }

      image = Content.Field.Image.from_api(image_data)

      assert image.alt == image_data["alt"]
      assert image.url == "http://#{site_app_domain()}/files/purple-train.jpeg"
    end
  end
end

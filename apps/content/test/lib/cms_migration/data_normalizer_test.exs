defmodule Content.CmsMigration.DataNormalizerTest do
  use ExUnit.Case
  import Content.CmsMigration.DataNormalizer

  describe "update_relative_links/3" do
    test "updates the provided relative path to include the given host" do
      host = "http://host.example"
      path = "uploaded/path"
      string = ~s(<a href="/#{path}/Flyer.pdf">Click for details</a>)

      result = update_relative_links(string, path, host)

      assert result == ~s(<a href=\"#{host}/#{path}/Flyer.pdf\">Click for details</a>)
    end

    test "given an additional backward slash is included" do
      host = "http://host.example"
      path = "uploaded/path"
      string = ~s(<a href=\"/#{path}/Flyer.pdf\">Click for details</a>)

      result = update_relative_links(string, path, host)

      assert result == ~s(<a href=\"#{host}/#{path}/Flyer.pdf\">Click for details</a>)
    end

    test "does not duplicate the host if a host is already present" do
      host = "http://host.example"
      path = "uploaded"
      string = ~s(<a href="#{host}/#{path}/Flyer.pdf">Click for details</a>)

      result = update_relative_links(string, path, host)

      assert result == ~s(<a href=\"#{host}/#{path}/Flyer.pdf\">Click for details</a>)
    end

    test "is case-insensitive" do
      host = "http://host.example"
      path = "uploadedpath"
      string = ~s(<a href="/uploadedPath/Flyer.pdf">Click for details</a>)

      result = update_relative_links(string, path, host)

      assert result == ~s(<a href=\"#{host}/#{path}/Flyer.pdf\">Click for details</a>)
    end
  end

  describe "update_relative_image_paths/3" do
    test "updates the provided relative image path with the given host" do
      host = "http://host.example"
      path = "path"
      string = ~s(<img src="/#{path}/image.jpg" />)

      result = update_relative_image_paths(string, path, host)

      assert result == ~s(<img src=\"#{host}/#{path}/image.jpg\" />)
    end

    test "does not duplicate the host if a host is already present" do
      host = "http://host.example"
      path = "path"
      string = ~s(<img src="#{host}/#{path}/image.jpg" />)

      result = update_relative_image_paths(string, path, host)

      assert result == ~s(<img src=\"#{host}/#{path}/image.jpg\" />)
    end

    test "is case-insensitive" do
      host = "http://host.example"
      path = "uploadedimage"
      string = ~s(<img src="/uploadedImage/image.jpg" />)

      result = update_relative_image_paths(string, path, host)

      assert result == ~s(<img src=\"#{host}/#{path}/image.jpg\" />)
    end
  end

  describe "remove_style_information/1" do
    test "removes style attributes" do
      value = ~s(<a href=\"www.mbta.example\" style=\"text-align: center;\" target=\"_blank\">Example</a>)

      result = remove_style_information(value)

      assert result == ~s(<a href=\"www.mbta.example\" target=\"_blank\">Example</a>)
    end

    test "removes style tags" do
      value = ~s(<p>Hello</p><style type="text/css">h1 {color:red;}</style>)

      result = remove_style_information(value)

      assert result == "<p>Hello</p>"
    end
  end
end

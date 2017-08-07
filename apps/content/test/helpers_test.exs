defmodule Content.HelpersTest do
  use ExUnit.Case, async: true

  import Content.Helpers

  describe "rewrite_url/1" do
    test "rewrites when the URL has query params" do
      rewritten = rewrite_url("http://test-mbta.pantheonsite.io/foo/bar?baz=quux")
      assert rewritten == Content.Config.apply(:static, ["/foo/bar?baz=quux"])
    end

    test "rewrites when the URL has no query params" do
      rewritten = rewrite_url("http://test-mbta.pantheonsite.io/foo/bar")
      assert rewritten == Content.Config.apply(:static, ["/foo/bar"])
    end

    test "rewrites the URL for https" do
      rewritten = rewrite_url("https://example.com/foo/bar")
      assert rewritten == Content.Config.apply(:static, ["/foo/bar"])
    end
  end

  describe "parse_image/2" do
    test "parses image data and rewrites URL" do
      data = %{
        "field_my_image" => [%{
          "alt" => "Picture of a barn",
          "url" => "/foo/barn.jpg",
        }]
      }

      assert %Content.Field.Image{
        alt: "Picture of a barn",
        url: url
      } = parse_image(data, "field_my_image")

      assert url == Content.Config.apply(:static, ["/foo/barn.jpg"])
    end
  end

  describe "parse_link/2" do
    test "it parses a link field into a Link" do
      data = %{
        "field_my_link" => [%{
          "title" => "This is the link text",
          "uri" => "internal:/this/is/the/link/url"
        }]
      }

      assert %Content.Field.Link{
        title: "This is the link text",
        url: "/this/is/the/link/url"
      } = parse_link(data, "field_my_link")
    end

    test "it returns nil if unexpected format" do
      data = %{
        "field_my_link" => %{
          hmmm: "what is this?"
        }
      }

      assert parse_link(data, "field_my_link") == nil
    end
  end

  describe "parse_updated_at/1" do
    test "handles unix time as a string" do
      api_data = %{"changed" => [%{"value" => "1488904773"}]}
      assert parse_updated_at(api_data) == DateTime.from_unix!(1_488_904_773)
    end

    test "handles unix time as an int" do
      api_data = %{"changed" => [%{"value" => 1_488_904_773}]}
      assert parse_updated_at(api_data) == DateTime.from_unix!(1_488_904_773)
    end
  end

  describe "int_or_string_to_int/1" do
    test "converts appropriately or leaves alone" do
      assert int_or_string_to_int(5) == 5
      assert int_or_string_to_int("5") == 5
    end

    test "handles invalid string" do
      assert int_or_string_to_int("foo") == nil
    end

    test "handles nil" do
      assert int_or_string_to_int(nil) == nil
    end
  end

  describe "handle_html/1" do
    test "removes unsafe html tags from safe content" do
      html = "<h1>hello!<script>code</script></h1>"
      assert handle_html(html) == {:safe, "<h1>hello!code</h1>"}
    end

    test "allows valid HTML5 tags" do
      html = "<p>Content</p>"
      assert handle_html(html) == {:safe, "<p>Content</p>"}
    end

    test "rewrites static file links" do
      html = "<img src=\"/sites/default/files/converted.jpg\">"
      assert handle_html(html) == {:safe, "<img src=\"http://localhost:4001/sites/default/files/converted.jpg\" />"}
    end

    test "allows an empty string" do
      assert handle_html("") == {:safe, ""}
    end

    test "allows nil" do
      assert handle_html(nil) == {:safe, ""}
    end
  end

  describe "parse_paragraphs/1" do
    test "it parses different kinds of paragraphs" do
      api_data = %{"field_paragraphs" => [
        %{
          "type" => [%{"target_id" => "custom_html"}],
          "field_custom_html_body" =>  [%{"value" => "some HTML"}]
        },
        %{
          "type" => [%{"target_id" => "title_card_set"}],
          "field_title_cards" => [%{
            "type" => [%{"target_id" => "title_card"}],
            "field_title_card_body" => [%{"value" => "body"}],
            "field_title_card_link" => [%{"uri" => "internal:/foo/bar"}],
            "field_title_card_title" => [%{"value" => "title"}]
          }],
        }
      ]}

      parsed = parse_paragraphs(api_data)

      assert parsed == [
        %Content.Paragraph.CustomHTML{body: Phoenix.HTML.raw("some HTML")},
        %Content.Paragraph.TitleCardSet{
          title_cards: [%Content.Paragraph.TitleCard{
            body: Phoenix.HTML.raw("body"),
            title: "title",
            link: %Content.Field.Link{
              url: "/foo/bar",
            }
          }]
        }
      ]
    end
  end

  describe "parse_link_text/2" do
    test "returns the link text" do
      data = %{
        "field_link_example" => [
          %{
            "options" => [],
            "title" => "Link Text",
            "uri" => "www.example.com"
          }
        ]
      }

      assert parse_link_text(data, "field_link_example") == "Link Text"
   end

   test "returns nil when the given key does not exist" do
     assert parse_link_text(%{}, "key_does_not_exist") == nil
   end
  end
end

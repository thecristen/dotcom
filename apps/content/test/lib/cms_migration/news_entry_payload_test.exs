defmodule Content.CmsMigration.NewsEntryPayloadTest do
  use ExUnit.Case, async: true
  import Content.FixtureHelpers
  import Content.CmsMigration.NewsEntryPayload

  @news_entry_json "cms_migration/valid_news_entry/news_entry.json"
  @former_mbta_site_host Application.get_env(:site, :former_mbta_site)[:host]

  describe "build/1" do
    test "maps the news entry data to the CMS News Entry fields" do
      news_entry_data = fixture(@news_entry_json)

      news_entry_payload = build(news_entry_data)

      assert news_entry_payload[:type] == [%{target_id: "news_entry"}]
      assert news_entry_payload[:title] == [%{value: "News Entry Title"}]
      assert news_entry_payload[:body] == [
        %{value: "Important news content.", format: "basic_html"}
      ]
      assert news_entry_payload[:field_media_contact] == [%{value: "Leslie Knope"}]
      assert news_entry_payload[:field_media_phone] == [%{value: "617-222-3344"}]
      assert news_entry_payload[:field_media_email] == [%{value: "knope@mbta.com"}]
      assert news_entry_payload[:field_posted_on] == [%{value: "2017-03-01"}]
      assert news_entry_payload[:field_migration_id] == [%{value: "1"}]
    end

    test "relative links are updated to include the former mbta site host" do
      body_with_external_link = "<a href=\"/uploadedfiles/Flyer.pdf\">Click for details</a>"

      news_entry_data =
        @news_entry_json
        |> fixture
        |> Map.put("information", body_with_external_link)

      %{body: [%{value: value}]} = build(news_entry_data)

      assert value =~ "<a href=\"#{@former_mbta_site_host}/uploadedfiles/Flyer.pdf\">Click for details</a>"
    end

    test "relative images are updated to include the former mbta site host" do
      content_with_image = "<img alt=\"AACT\" src=\"/uploadedimages/Press_Releases/AACT.jpg\" />"

      news_entry_data =
        @news_entry_json
        |> fixture
        |> Map.put("information", content_with_image)

      %{body: [%{value: value}]} = build(news_entry_data)

      assert value =~ "<img alt=\"AACT\" src=\"#{@former_mbta_site_host}/uploadedimages/Press_Releases/AACT.jpg\" />"
    end

    test "removes style information in the body field" do
      body_with_style_info =
      ~s(<style type=\"text/css\">table td{vertical-align:top;}</style>) <>
      ~s(<p><span style="FONT-FAMILY: 'Arial', 'sans-serif'\">News Content</span></p>)

      news_entry_data =
        @news_entry_json
        |> fixture()
        |> Map.put("information", body_with_style_info)

      %{body: [%{value: value}]} = build(news_entry_data)

      assert value =~ "<p><span>News Content</span></p>"
    end

    test "handles the event_date format {0M}/{0D}/{YYYY}" do
      news_entry_data =
        @news_entry_json
        |> fixture
        |> Map.put("event_date", "01/10/2017")

      %{field_posted_on: [%{value: date}]} = build(news_entry_data)

      assert date == "2017-01-10"
    end

    test "handles the event_date format {Mfull} {0D}, {YYYY}" do
      news_entry_data =
        @news_entry_json
        |> fixture
        |> Map.put("event_date", "January 10, 2017")

      %{field_posted_on: [%{value: date}]} = build(news_entry_data)

      assert date == "2017-01-10"
    end
  end
end

defmodule Content.CmsMigration.NewsEntryPayloadTest do
  use ExUnit.Case, async: true
  import Content.FixtureHelpers
  import Content.CmsMigration.NewsEntryPayload

  @news_entry_json "cms_migration/valid_news_entry/news_entry.json"
  @former_mbta_site_host Application.get_env(:site, :former_mbta_site)[:host]

  describe "build/1" do
    test "maps the news entry data to the CMS News Entry fields" do
      news_entry_data = fixture(@news_entry_json)

      %{
        body: [%{format: body_format, value: body}],
        field_media_contact: [%{value: media_contact}],
        field_media_email: [%{value: media_email}],
        field_media_phone: [%{value: media_phone}],
        field_migration_id: [%{value: migration_id}],
        field_posted_on: [%{value: posted_on}],
        field_teaser: [%{value: teaser}],
        title: [%{value: title}],
        type: [%{target_id: type}]
      } = build(news_entry_data)

      assert body =~ "Necessary track work near Copley Station"
      assert body_format == "basic_html"
      assert type == "news_entry"
      assert title == "Buses replacing Green Line Service"
      assert teaser =~ "Necessary track work near Copley Station"
      assert String.length(teaser) == 255
      assert media_contact == "Leslie Knope"
      assert media_phone == "617-222-3344"
      assert media_email == "knope@mbta.com"
      assert posted_on == "2017-03-01"
      assert migration_id == "1"
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

    test "handles the event_date format {0M}/{0D}/{YY}" do
      news_entry_data =
        @news_entry_json
        |> fixture
        |> Map.put("event_date", "01/10/17")

      %{field_posted_on: [%{value: date}]} = build(news_entry_data)

      assert date == "2017-01-10"
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

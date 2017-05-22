defmodule Content.CmsMigration.EventPayloadTest do
  use ExUnit.Case, async: true
  import Content.FixtureHelpers
  import Content.CmsMigration.EventPayload

  @meeting "cms_migration/valid_meeting/meeting.json"

  describe "from_meeting/1" do
    test "maps meeting information to CMS event fields" do
      meeting = fixture(@meeting)

      event_payload = from_meeting(meeting)

      assert event_payload[:type] == [%{target_id: "event"}]
      assert event_payload[:title] == [%{value: "Fare Increase Proposal"}]
      assert event_payload[:body] == [%{value: "Discuss fare increase proposal.", format: "basic_html"}]
      assert event_payload[:field_who] == [%{value: "Staff"}]
      assert event_payload[:field_imported_address] == [%{value: "Dudley Square Branch Library"}]
      assert event_payload[:field_start_time] == [%{value: "2006-08-30T14:00:00"}]
      assert event_payload[:field_end_time] == [%{value: "2006-08-30T17:00:00"}]
      assert event_payload[:field_meeting_id] == [%{value: 5550}]
    end

    test "removes all html tags from the location field" do
      meeting =
        @meeting
        |> fixture()
        |> Map.put("location", "<p>Address</p> with html<br> tags.")

      event_payload = from_meeting(meeting)

      assert event_payload[:field_imported_address] == [%{
        value: "Address with html tags."
      }]
    end

    test "removes all html tags from the title field" do
      meeting =
        @meeting
        |> fixture()
        |> Map.put("organization", "2007 Upcoming <b>AACT</b> Meetings")

      event_payload = from_meeting(meeting)

      assert event_payload[:title] == [%{
        value: "2007 Upcoming AACT Meetings"
      }]
    end

    test "removes style attributes in the body field" do
      text_with_style_attr = "<a href=\"www.mbta.com\" style=\"text-align: center;\" target=\"_blank\">Example</a>"
      meeting =
        @meeting
        |> fixture()
        |> Map.put("objective", text_with_style_attr)

      %{body: [%{value: value}]} = from_meeting(meeting)

      assert value == "<a href=\"www.mbta.com\" target=\"_blank\">Example</a>"
    end

    test "relative links are updated to include the former mbta site host" do
      former_mbta_site_host = Application.get_env(:site, :former_mbta_site)[:host]

      body_with_external_link = "<a href=\"/uploadedfiles/Meeting/BeverlyCommRail-PTC_Meeting Flyer.pdf\">Click for details</a>"

      meeting =
        @meeting
        |> fixture()
        |> Map.put("objective", body_with_external_link)

      %{body: [%{value: value}]} = from_meeting(meeting)

      assert value =~ "<a href=\"#{former_mbta_site_host}/uploadedfiles/Meeting/BeverlyCommRail-PTC_Meeting Flyer.pdf\">Click for details</a>"
    end
  end
end

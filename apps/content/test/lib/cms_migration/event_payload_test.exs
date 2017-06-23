defmodule Content.CmsMigration.EventPayloadTest do
  use ExUnit.Case, async: true
  import Content.JsonHelpers
  import Content.CmsMigration.EventPayload

  @meeting "fixtures/cms_migration/valid_meeting/meeting.json"

  describe "from_meeting/1" do
    test "maps meeting information to CMS event fields" do
      meeting = parse_json_file(@meeting)

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
        |> parse_json_file()
        |> Map.put("location", "<p>Address</p> with html<br> tags.")

      event_payload = from_meeting(meeting)

      assert event_payload[:field_imported_address] == [%{
        value: "Address with html tags."
      }]
    end

    test "removes all html tags from the title field" do
      meeting =
        @meeting
        |> parse_json_file()
        |> Map.put("organization", "2007 Upcoming <b>AACT</b> Meetings")

      event_payload = from_meeting(meeting)

      assert event_payload[:title] == [%{
        value: "2007 Upcoming AACT Meetings"
      }]
    end

    test "removes style information in the body field" do
      body_with_style_info =
      ~s(<style type=\"text/css\">table td{vertical-align:top;}</style>) <>
      ~s(<a href=\"www.mbta.com\" style=\"text-align: center;\" target=\"_blank\">Example</a>)

      meeting =
        @meeting
        |> parse_json_file()
        |> Map.put("objective", body_with_style_info)

      %{body: [%{value: value}]} = from_meeting(meeting)

      assert value == "<a href=\"www.mbta.com\" target=\"_blank\">Example</a>"
    end

    test "relative links are updated to include the former mbta site host" do
      former_mbta_site_host = Application.get_env(:site, :former_mbta_site)[:host]

      body_with_external_link = "<a href=\"/uploadedfiles/Flyer.pdf\">Click for details</a>"

      meeting =
        @meeting
        |> parse_json_file()
        |> Map.put("objective", body_with_external_link)

      %{body: [%{value: value}]} = from_meeting(meeting)

      assert value =~ "<a href=\"#{former_mbta_site_host}/uploadedfiles/Flyer.pdf\">Click for details</a>"
    end
  end
end

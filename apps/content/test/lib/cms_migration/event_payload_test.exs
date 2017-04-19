defmodule Content.CmsMigration.EventPayloadTest do
  use ExUnit.Case, async: true
  import Content.FixtureHelpers
  import Content.CmsMigration.EventPayload

  @meeting "cms_migration/meeting.json"

  describe "from_meeting/1" do
    test "maps meeting information to CMS event fields" do
      meeting = fixture(@meeting)

      event_payload = from_meeting(meeting)

      assert event_payload[:type] == [%{target_id: "event"}]
      assert event_payload[:title] == [%{value: "Fare Increase Proposal"}]
      assert event_payload[:body] == [%{value: "Discuss fare increase proposal."}]
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
  end
end

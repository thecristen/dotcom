defmodule Content.EventTest do
  use ExUnit.Case, async: true

  alias Content.Event
  import Content.Event
  import Phoenix.HTML, only: [safe_to_string: 1]

  setup do
    %{api_event: Content.CMS.Static.events_response() |> List.first}
  end

  describe "from_api/1" do
    test "it parses the response", %{api_event: api_event} do
      assert %Event{
        id: id,
        start_time: start_time,
        end_time: end_time,
        title: title,
        location: location,
        street_address: street_address,
        city: city,
        state: state,
        who: who,
        body: body,
        notes: notes,
        agenda: agenda
      } = from_api(api_event)

      assert id == 17
      assert start_time == Timex.parse!("2017-01-23T15:00:00Z", "{ISO:Extended:Z}")
      assert end_time == nil
      assert title == "Finance & Audit Committee Meeting"
      assert location == "MassDOT"
      assert street_address == "10 Park Plaza"
      assert city == "Boston"
      assert state == "MA"
      assert who == "Board Members"
      assert safe_to_string(body) =~ "<p><strong>Massachusetts"
      assert safe_to_string(notes) =~ "<p><strong>THIS AGENDA"
      assert safe_to_string(agenda) =~ "<p><strong>Call to Order Chair"
    end
  end

  describe "past?/2" do
    @yesterday ~D[2018-01-01]
    @today ~D[2018-01-02]
    @tomorrow ~D[2018-01-03]

    test "event yesterday is in the past" do
      assert past?(%Event{start_time: @yesterday}, @today) == true
    end

    test "event tomorrow not in the past" do
      assert past?(%Event{start_time: @tomorrow}, @today) == false
    end

    test "event today is not in the past" do
      assert past?(%Event{start_time: @today}, @today) == false
    end
  end
end

defmodule Content.EventTest do
  use ExUnit.Case, async: true

  alias Content.Event
  import Content.Event
  import Phoenix.HTML, only: [safe_to_string: 1]

  setup do
    %{api_event_without_path_alias: Content.CMS.Static.events_response() |> Enum.at(0),
      api_event_with_path_alias: Content.CMS.Static.events_response() |> Enum.at(1)}
  end

  describe "from_api/1" do
    test "it parses the response without path alias", %{api_event_without_path_alias: api_event} do
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
        agenda: agenda,
        path_alias: path_alias
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
      assert path_alias == "17"
    end

    test "it parses the response with path alias", %{api_event_with_path_alias: api_event} do
      assert %Event{
        path_alias: path_alias
      } = from_api(api_event)

      assert path_alias == "path_to/path_alias"
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

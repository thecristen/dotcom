defmodule Content.Factory do
  import Phoenix.HTML, only: [raw: 1]

  def event_factory do
    %Content.Event{
      id: 1,
      body: raw("AACT Meetings are held in the State Transportation Building."),
      title: "AACT Membership Meeting",
      location: "MassDOT",
      street_address: "10 Park Plaza",
      city: "Boston",
      state: "MA",
      start_time: Timex.now(),
      end_time: Timex.shift(Timex.now(), hours: 1),
      agenda: raw("Event Agenda"),
      notes: raw("Event Notes"),
      who: "Board Members",
      meeting_id: nil,
      imported_address: nil
    }
  end
end

defmodule Content.Factory do
  def event_page_factory do
    %Content.Page{
      id: 1,
      body: "AACT Meetings are held in the State Transportation Building.",
      title: "AACT Membership Meeting",
      type: "event",
      fields: %{
        location: "MassDOT",
        street_address: "10 Park Plaza",
        city: "Boston",
        state: "MA",
        start_time: Timex.now(),
        end_time: Timex.shift(Timex.now(), hours: 1),
        agenda: "Event Agenda",
        notes: "Event Notes",
        who: "Board Members"
      }
    }
  end
end

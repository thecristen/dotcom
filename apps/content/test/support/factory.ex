defmodule Content.Factory do
  def event_page_factory do
    %Content.Page{
      id: 1,
      body: "AACT Meetings are held in the State Transportation Building.",
      title: "AACT Membership Meeting",
      type: "event",
      fields: %{
        address: "10 Park Plaza, Conference Room 2",
        agenda: "Event Agenda",
        start_time: Timex.now(),
        end_time: Timex.shift(Timex.now(), hours: 1),
        map_address: "10 Park Plaza Boston, MA",
        notes: "Event Notes",
        who: "Board Members"
      }
    }
  end
end

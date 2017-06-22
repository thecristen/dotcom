defmodule Content.Paragraph.UpcomingBoardMeetings do
  defstruct [events: []]

  @type t :: %__MODULE__{
    events: [Content.Event.t]
  }

  @spec from_api(map) :: t
  def from_api(data) do
    events =
      data
      |> Map.get("view_data", [])
      |> Enum.map(&Content.Event.from_api/1)

    %__MODULE__{
      events: events
    }
  end
end

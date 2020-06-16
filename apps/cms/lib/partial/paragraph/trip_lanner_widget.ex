defmodule CMS.Partial.Paragraph.TripPlannerWidget do
  @moduledoc """
  Represents a Trip Planner widget on the page.
  """

  @type t :: %__MODULE__{
          partial: String.t(),
          right_rail: boolean
        }

  defstruct partial: "_trip_planner_widget.html",
            right_rail: true
end

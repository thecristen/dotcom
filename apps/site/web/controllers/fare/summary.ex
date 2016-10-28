defmodule Site.FareController.Summary do
  @moduledoc """

  Represents a summarization of fares to display on the index page.

  * name: the name of the fare. Something like "Subway One Way" or "Monthly Pass"
  * modes: the list of mode atoms this fare is valid on
  * fares: a list of tuples: {"media name", "price value"}

  `name` and `fares` should already be rendered for display.
  """
  @type t :: %__MODULE__{
    name: String.t,
    modes: [Routes.Route.route_type],
    fares: [{String.t, String.t | iolist}]
  }

  defstruct [
    name: "",
    modes: [],
    fares: []
  ]
end

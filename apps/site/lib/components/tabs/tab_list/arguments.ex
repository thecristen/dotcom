defmodule Site.Components.Tabs.TabList do
  @moduledoc """
  Renders a list of tabs.
  """

  import Site.Router.Helpers

  defstruct [
    links: [
      {"Schedule", stop_path(Site.Endpoint, :show, "place-sstat", tab: "schedule"), true},
      {"Station Information", stop_path(Site.Endpoint, :show, "place-sstat", tab: "info"), false}
    ],
    class: ""
  ]

  @type t :: %__MODULE__{
    links: [{Phoenix.HTML.Safe.t, String.t, boolean}],
    class: String.t
  }

  def tab_class(true), do: "tab-list-tab tab-list-selected"
  def tab_class(false), do: "tab-list-tab"
end

defmodule Site.Components.Tabs.TabList do
  @moduledoc """
  Renders a list of tabs.
  """

  import Site.Router.Helpers

  defstruct [
    id: "tab-select",
    class: "",
    links: [
      {"Schedule", stop_path(Site.Endpoint, :show, "place-sstat", tab: "schedule"), true},
      {"Station Information", stop_path(Site.Endpoint, :show, "place-sstat", tab: "info"), false}
    ],
    collapsed: "xs"
  ]

  @type t :: %__MODULE__{
    links: [{String.t, String.t, boolean}],
    class: String.t,
    collapsed: String.t
  }

  def tab_links(links) do
    Enum.map(links, fn {title, href, _selected} -> {title, href} end)
  end

  def selected_tab(links) do
    links
    |> Enum.find(fn {_, _, selected?} -> selected? end)
    |> elem(0)
  end
end

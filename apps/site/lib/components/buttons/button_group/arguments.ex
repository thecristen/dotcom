defmodule Site.Components.Buttons.ButtonGroup do
  @moduledoc """
  Convenience function for rendering a formatted list of links. Links should be passed as
  a list of [{text, href}]. The link text can either be a string, or a list of child elements
  like what would be passed to Phoenix.HTML.Link.
  """
  defstruct class:   "",
            id:      nil,
            links:   [
              {"Sample link 1", Site.Router.Helpers.page_path(Site.Endpoint, :index)},
              {"Sample link 2", Site.Router.Helpers.page_path(Site.Endpoint, :index)}
            ]

  @type t :: %__MODULE__{
    class: String.t,
    id: String.t | nil,
    links: [button_arguments]
  }

  @type button_arguments :: {button_content, String.t}
  @type button_content :: String.t | [String.t | Phoenix.HTML.Safe.t]
end

defmodule Site.SearchHelpers do
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML.Form, only: [form_for: 4, search_input: 3]

  @form_options [as: :search, method: :get]
  @placeholder "Search by keyword"

  @spec desktop_form(Plug.Conn.t) :: Phoenix.HTML.safe
  def desktop_form(conn) do
    form_for conn, "/search", @form_options, fn f ->
      [
        search_input(:search, :query, value: f.params["query"], placeholder: @placeholder, autocomplete: "off",
                     data: [input: "search"]),
        content_tag :button, class: "search-button search-button-xl", aria: [label: "submit search"] do
          Site.PageView.svg_icon(%Site.Components.Icons.SvgIcon{icon: :search, show_tooltip?: false})
        end
      ]
    end
  end
end

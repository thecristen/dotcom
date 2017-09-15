defmodule Site.SearchHelpers do
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML.Form, only: [form_for: 4, search_input: 3]
  import Site.Router.Helpers, only: [search_path: 2]

  @form_options [as: :search, method: :get]
  @placeholder "Search by keyword"

  @spec desktop_form(Plug.Conn.t, boolean) :: Phoenix.HTML.safe
  def desktop_form(conn, show_query?) do
    form_for conn, search_path(conn, :index), @form_options, fn _ ->
      [
        search_input(:search, :query, value: get_search_from_query(conn, show_query?), placeholder: @placeholder,
                     autocomplete: "off", data: [input: "search"]),
        content_tag :button, class: "search-button search-button-xl", aria: [label: "submit search"] do
          Site.PageView.svg_icon(%Site.Components.Icons.SvgIcon{icon: :search, show_tooltip?: false})
        end
      ]
    end
  end

  @spec get_search_from_query(Plug.Conn.t, boolean) :: String.t
  defp get_search_from_query(_, false), do: ""
  defp get_search_from_query(%{query_params: %{"search" => %{"query" => query}}}, true), do: query
  defp get_search_from_query(_, _), do: ""
end

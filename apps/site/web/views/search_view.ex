defmodule Site.SearchView do
  use Site.Web, :view
  import Site.ContentView, only: [render_duration: 2]
  import Site.ContentRewriter, only: [rewrite: 1]
  alias Content.SearchResult.Event
  alias Content.SearchResult.LandingPage
  alias Content.SearchResult.NewsEntry
  alias Content.SearchResult.Page
  alias Content.SearchResult.Person
  alias Content.SearchResult.File

  defdelegate fa_icon_for_file_type(mime), to: Site.FontAwesomeHelpers

  @spec render_filter_option(Phoenix.HTML.Form, atom, map) :: Phoenix.HTML.safe
  def render_filter_option(form, type, option) do
    id = "#{type}_#{option.value}"
    name = "search[#{type}][#{option.value}]"
    content_tag :li do
      label form, type, for: id, class: "facet-label" do
        [content_tag(:input, "", type: "checkbox", id: id, name: name, value: "true", checked: option.active?),
         content_tag(:span, "#{option.label} (#{option.count})")]
      end
    end
  end

  @spec render_toggle_filter() :: [Phoenix.HTML.safe]
  def render_toggle_filter do
    [content_tag(:span, fa("plus-circle"), class: "search-filter-expand"),
     content_tag(:span, fa("minus-circle"), class: "search-filter-collapse")]
  end

  @spec icon(Content.Search.result) :: Phoenix.HTML.safe | String.t
  defp icon(%Event{}), do: fa "calendar"
  defp icon(%NewsEntry{}), do: fa "newspaper-o"
  defp icon(%Person{}), do: fa "user"
  defp icon(%LandingPage{}), do: fa "file-o"
  defp icon(%Page{}), do: fa "file-o"
  defp icon(%File{mimetype: mimetype}), do: fa_icon_for_file_type(mimetype)

  @spec fragment(Content.Search.result) :: Phoenix.HTML.safe | String.t
  defp fragment(%NewsEntry{highlights: higlights}), do: highlights(higlights)
  defp fragment(%Person{highlights: higlights}), do: highlights(higlights)
  defp fragment(%Page{highlights: higlights}), do: highlights(higlights)
  defp fragment(%LandingPage{highlights: higlights}), do: highlights(higlights)
  defp fragment(%Event{start_time: start_time, location: location}) do
    [content_tag(:div, render_duration(start_time, nil)), content_tag(:div, "#{location}")]
  end
  defp fragment(_), do: ""

  @spec highlights([String.t]) :: Phoenix.HTML.safe
  defp highlights(html_strings) do
    html_strings
    |> raw()
    |> rewrite()
  end
end

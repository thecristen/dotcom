defmodule Site.SearchView do
  use Site.Web, :view

  def render_filter_option(form, type, option) do
    id = "#{Atom.to_string(type)}_#{option.value}"
    name = "search[#{type}][#{option.value}]"
    content_tag :li do
      label form, type, for: id, class: "facet-label" do
        [
          content_tag(:input, "", type: "checkbox", id: id, name: name, value: "true", checked: option.active?),
          content_tag :span do
            "#{option.label} (#{option.count})"
          end
        ]
      end
    end
  end

  def render_document(document) do
    content_tag :li do
      [
        content_tag :a, href: document.url do
          [
            document_icon(document.type),
            document.title
          ]
        end,
        content_tag :div do
          document.fragment
        end
      ]
    end
  end

  def render_toggle_filter do
    [
      content_tag :span, class: "search-filter-expand" do
        fa "plus-circle"
      end,
      content_tag :span, class: "search-filter-collapse" do
        fa "minus-circle"
      end
    ]
  end

  defp document_icon("event") do
    fa "calendar"
  end
  defp document_icon("news") do
    fa "newspaper-o"
  end
  defp document_icon("people") do
    fa "user"
  end
  defp document_icon("project") do
    fa "line-chart"
  end
  defp document_icon("policy") do
    fa "gavel"
  end
  defp document_icon("division") do
    fa "users"
  end
  defp document_icon("document") do
    fa "file-pdf-o"
  end

end

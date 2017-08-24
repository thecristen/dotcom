defmodule Site.SearchController.Results do
  def sample_data(search_input) do
    content_filter = Map.get(search_input, "content_type", %{})
    year_filter = Map.get(search_input, "year", %{})

    facets = %{
      content_type: [%{label: "Events", value: "event", active?: Map.has_key?(content_filter, "event"), count: 4},
                     %{label: "News", value: "news", active?: Map.has_key?(content_filter, "news"), count: 1},
                     %{label: "Documents", value: "document", active?: Map.has_key?(content_filter, "document"),
                       count: 2}],
      year: [%{label: "2017", value: "2017", active?: Map.has_key?(year_filter, "2017"), count: 4},
             %{label: "2016", value: "2016", active?: Map.has_key?(year_filter, "2016"), count: 7}]
    }

    documents = [%{type: "event", title: "Green Line Extension Public Meeting", fragment: "May 1, 2017 @ 12pm",
                   url: "http://www.google.com"},
                 %{type: "news", title: "Green Line Extension Project Set to Begin", fragment: "description 2",
                   url: "http://www.yahoo.com"},
                 %{type: "people", title: "People", fragment: "test", url: "/"},
                 %{type: "project", title: "Project", fragment: "test", url: "/"},
                 %{type: "policy", title: "Policy", fragment: "test", url: "/"},
                 %{type: "division", title: "Division", fragment: "test", url: "/"},
                 %{type: "document", title: "Document", fragment: "test", url: "/"}]
    {facets, documents, 75}
  end
end

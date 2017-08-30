defmodule Content.SearchResult.Person do
  defstruct [
    title: "",
    url: "",
    highlights: ""
  ]

  @type t :: %__MODULE__{
    title: String.t,
    url: String.t,
    highlights: [String.t]
  }

  @spec build(map) :: t
  def build(result) do
    %__MODULE__{
      title: result["ts_title"],
      url: "/people/#{result["its_nid"]}",
      highlights: result["highlights"]
    }
  end
end

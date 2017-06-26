defmodule Site.ContentHelpers do
  @doc "Returns the text if present, otherwise returns nil"
  @spec content(String.t) :: String.t | nil
  @spec content(Phoenix.HTML.safe) :: Phoenix.HTML.safe | nil
  def content(nil) do
    nil
  end
  def content({:safe, string} = safe_html) do
    if content(string) do
      safe_html
    end
  end
  def content(string) do
    case String.trim(string) do
      "" -> nil
      string -> string
    end
  end
end

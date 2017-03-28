defmodule Site.ContentView do
  use Site.Web, :view
  import Site.TimeHelpers

  @doc "Returns true if the provided field has content."
  @spec field_has_content?(String.t | Enum.t) :: boolean
  def field_has_content?(content) when is_binary(content) do
    String.strip(content) != ""
  end
  def field_has_content?(nil) do
    false
  end
  def field_has_content?({:safe, content}) do
    field_has_content?(content)
  end
  def field_has_content?(content) do
    !Enum.empty?(content)
  end
end

defmodule Site.ContentRewriters.Links do

  @doc """
  Adds the target=_blank attribute to links that redirect to the old site so they open in a new tab.
  """
  @spec add_target_to_redirect(Floki.html_tree) :: Floki.html_tree
  def add_target_to_redirect({"a", attrs, children} = table_element) do
    case Floki.attribute(table_element, "href") do
      ["/redirect/" <> _] ->
        case Floki.attribute(table_element, "target") do
          [] -> {"a", [{"target", "_blank"} | attrs], children}
          _ -> table_element
        end
       _ -> table_element
    end
  end
end

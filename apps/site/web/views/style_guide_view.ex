defmodule Site.StyleGuideView do
  use Site.Web, :view
  import Site.Components.Helpers
  use Site.StyleGuideView.CssVariables

  def color_variables, do: @colors
  def font_size_variables, do: @font_sizes

  @spec get_css_value(String.t, atom) :: String.t
  @doc "Replaces any css variables with actual values."
  def get_css_value("$"<>_ = value, :colors), do: do_get_css_value(value, @colors)
  def get_css_value("$"<>_ = value, :font_sizes), do: do_get_css_value(value, @font_sizes)
  def get_css_value(value, _), do: value

  defp do_get_css_value(value, variable_map) do
    variable_map
    |> Map.to_list
    |> Enum.map(fn {_section, values} ->
      case Kernel.is_map(values) do
        true -> Map.get(values, value)
        false -> values
      end
    end)
    |> Enum.reject(&(&1 == nil))
    |> List.first
  end

  @spec render_component(atom, atom) :: Phoenix.HTML.Safe.t
  @spec render_component(atom, atom, map) :: Phoenix.HTML.Safe.t
  def render_component(component, group) when is_atom(component) and is_atom(group) do
    render_component(component, group, component_args(component, group))
  end
  def render_component(component, group, args) when is_atom(component) and is_atom(group) do
    apply(__MODULE__, component, [args])
  end

  def page_title(:audience_goals_tone), do: "Audience, Goals, and Tone"
  def page_title(:grammar_and_mechanics), do: "Grammar and Mechanics"
  def page_title(atom), do: String.capitalize Atom.to_string(atom)

  @spec component_markup(atom, atom) :: String.t
  def component_markup(component, group) when is_atom(component) and is_atom(group) do
    component
    |> render_component(group)
    |> Phoenix.HTML.safe_to_string
  end

  @spec component_description(atom, atom) :: String.t
  def component_description(component, group) when is_atom(component) and is_atom(group) do
    component
    |> component_module(group)
    |> Code.get_docs(:moduledoc)
    |> elem(1)
  end

  def get_variants(component, group) do
    case has_variants?(component, group) do
      true -> component |> component_module(group) |> apply(:variants, [])
      false -> []
    end
  end

  defp has_variants?(component, group) do
    component
    |> component_module(group)
    |> function_exported?(:variants, 0)
  end

  def needs_comma?(component, group, idx) do
    component
    |> component_args(group)
    |> Map.to_list
    |> length
    |> Kernel.>(idx + 1)
  end

  @spec get_tag(String.t) :: String.t
  @doc "Reads a string and parses an HTML tag name from it."
  def get_tag("$h" <> num), do: get_h_tag(num)
  def get_tag(_), do: "p"

  defp get_h_tag("1-xxl"), do: "h1"
  defp get_h_tag("2-xxl"), do: "h2"
  defp get_h_tag("3-xxl"), do: "h3"
  defp get_h_tag("4-xxl"), do: "h4"
  defp get_h_tag(num), do: "h#{num}"

  @spec get_element_name(String.t) :: Phoenix.HTML.Safe.t
  @doc "Reads a CSS variable name, parses it into human-readable form, and returns it as HTML."
  def get_element_name("$" <> elem) do
    elem
    |> String.replace("-xxl", "<br />(Large Screens)")
    |> String.split("-")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
    |> Phoenix.HTML.raw
  end

   @doc """
     Returns the component's default arguments as defined in its struct.
     Only intended to be used in templates/style_guide/show.html.eex.
   """
   @spec component_args(atom, atom) :: map
   def component_args(component, section) do
     component
     |> component_module(section)
     |> struct
     |> Map.from_struct
   end
end

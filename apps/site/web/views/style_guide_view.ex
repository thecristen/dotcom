defmodule Site.StyleGuideView do
  use Site.Web, :view
  import Site.Components.Helpers
  use Site.StyleGuideView.CssVariables

  def color_variables, do: @colors

  def get_color_value("$"<>_ = value), do: do_get_color_value(value)
  def get_color_value(value), do: value

  defp do_get_color_value(value) do
    @colors
    |> Map.to_list
    |> Enum.map(fn {_section, values} -> Map.get(values, value) end)
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

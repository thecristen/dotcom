defmodule Site.StyleGuideView do
  use Site.Web, :view

  import Site.Components.Helpers

  def color_variables do
    color_variables_map
    |> Map.to_list
    |> Enum.sort
  end

  defp color_variables_map do
    File.cwd!
    |> Path.join("apps/site/web/static/css/colors.json")
    |> File.read!
    |> Poison.Parser.parse!
  end

  def get_color_value(value) do
    Map.get(color_variables_map, value, value)
  end

  def render_component(component, group) do
    apply(__MODULE__, component, [component_args(component, group)])
  end

  def render_component(component, _, args) do
    apply(__MODULE__, component, [args])
  end

  def component_markup(component, group) do
    apply(__MODULE__, String.to_atom("#{component}_markup"), [component_args(component, group)])
  end

  def component_description(component) do
    __MODULE__
    |> apply(String.to_atom("#{component}_description"), [])
    |> Phoenix.HTML.raw
  end

  def get_variants(component, group) do
    case has_variants?(component, group) do
      true -> component |> component_module(group) |> apply(:variants, [])
      false -> []
    end
  end

  def has_variants?(component, group) do
    component
    |> component_module(group)
    |> function_exported?(:variants, 0)
  end

  def is_last(component, group, idx) do
    component
    |> component_args(group)
    |> Map.to_list
    |> length
    |> Kernel.>(idx + 1)
  end
end

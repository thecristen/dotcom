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
    component
    |> render_component(group)
    |> Phoenix.HTML.safe_to_string
  end

  def component_description(component, group) do
    path = component_folder_path("#{group}", "#{component}")
    description_path = Path.join(path, "/description.html.eex")
    EEx.eval_file(description_path, [], engine: Phoenix.HTML.Engine)
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

   @doc """
     Returns the component's default arguments as defined in its struct.
     Only intended to be used in templates/style_guide/show.html.eex.
   """
   @spec component_args(String.t, String.t) :: map
   def component_args(component, section) do
     component
     |> component_module(section)
     |> struct
     |> Map.from_struct
   end
end

defmodule Site.Components.Precompiler do
  @moduledoc """
  Compiles all components and makes them available to be called from a view.
  Attach this functionality to a view with Kernel.use/1 (applied to all views by default in Site.Web.view)
  """

  require EEx

  import Site.Components.Helpers

  defmacro __using__(_) do
    quote do
      require EEx
      import unquote(__MODULE__)
      precompile_components
    end
  end

  @doc """
    Finds all folders within apps/site/lib/components, identifies those as "sections",
    and compiles a module for each folder in every section.
  """
  # not sure if this spec is correct -- does it return a def?
  @spec precompile_components :: nil
  defmacro precompile_components do
    sections = File.ls!(components_folder_path)
    for section <- sections do
      if File.dir?(components_section_path(section)) do
        quote do: unquote get_components(section)
      end
    end
  end

  @doc """
    Compiles a module for each folder within a component section
  """
  @spec get_components(String.t) :: nil
  def get_components(section) do
    components = File.ls!(components_section_path(section))
    for component <- components do
      if File.dir?(component_folder_path(section, component)) do
        quote do: unquote precompile_component(component, section)
      end
    end
  end


  @doc """
    Defines 3 functions on a view (component = "button"):
          button/1
          button_markup/1
          button_description/0.
    When rendering a component from within a normal view, call button/1.
    When rendering from within another component, call button_markup/1.
    button_description is only called in templates/style_guide/show.html.eex.
  """
  @spec precompile_component(String.t, String.t) :: nil
  def precompile_component(component, section) do
    name = String.to_atom(component)
    markup = String.to_atom("#{component}_markup")
    description = String.to_atom("#{component}_description")
    path = component_folder_path(section, component)
    if !File.exists?(component_folder_path(section, component) <> "/description.html.eex") do
      IO.warn "Description missing for #{name}"
    end

    use Phoenix.HTML
    quote do
      import Site.ViewHelpers
      import Site.Components.Helpers
      import unquote(component_module(component, section))

      # spec: button_description(args) :: String.t
      # Only called in templates/style_guide/show, where it is piped to Phoenix.HTML.raw
      EEx.function_from_file(:def, unquote(description), unquote(Path.join(path, "/description.html.eex")), [])

      # spec: button_markup(args) :: String.t
      EEx.function_from_file(:def, unquote(markup), unquote(Path.join(path, "/component.html.eex")), [:args])

      # spec: button(args) :: html
      def unquote(name)(arguments) do
        unquote(markup)(arguments) |> Phoenix.HTML.raw
      end

    end
  end

  @doc """
    Returns the component's default arguments as defined in its struct.
    Only intended to be used in templates/style_guide/show.html.eex.
  """
  @spec component_args(String.t, String.t) :: map
  def component_args(component, section) do
    args = component
    |> component_module(section)
    |> struct
    |> Map.from_struct
    quote do: unquote(args)
  end

  @doc """
    Returns any CSS states defined in the component (i.e. hover, active, focus, etc.)
    Only intended to be used in templates/style_guide/show.html.eex.
  """
  @spec component_states(String.t, String.t) :: [String.t] | nil
  def component_states(component, section) do
    states = component_module(component, section).states || nil
    quote do: unquote(states)
  end

end

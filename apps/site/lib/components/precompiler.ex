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
        get_components(section)
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
        precompile_component(component, section)
      end
    end
  end


  @doc """
  Defines function to render a particular component.  For example:

      precompile_component("mode_button", "buttons")

  defines the function `mode_button/1`, taking the variables to assign and
  returning a `Phoenix.HTML.Safe.t`.
  """
  @spec precompile_component(String.t, String.t) :: nil
  def precompile_component(component, section) do
    name = String.to_atom(component)
    path = Path.join(
      component_folder_path(section, component),
      "/component.html.eex")
    module = component_module(component, section)

    quote do
      import Site.ViewHelpers
      import Site.Components.Helpers
      import unquote(module)

      @spec unquote(name)(Dict.t) :: Phoenix.HTML.Safe.t
      EEx.function_from_file(
        :def,
        unquote(name),
        unquote(path),
        [:args],
        engine: Phoenix.HTML.Engine)
    end
  end
end

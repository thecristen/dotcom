defmodule Site.Components.Register do
  @moduledoc """
    Registers an @components attribute on a controller.
    Only used by style_guide_controller at the moment -- perhaps doesn't need to be its own module...
  """

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      import Site.Components.Helpers
      Module.register_attribute(__MODULE__, :components, persist: true)

      @components get_components
    end
  end

  @doc """
    Finds all folders within apps/site/lib/components, and returns a tuple {:section, [:component...]} for each
  """
  @spec get_components :: [{atom, [atom]}]
  defmacro get_components do
    quote do
      components_folder_path
      |> File.ls!
      |> Enum.filter(&(File.dir?(Path.join(components_folder_path, &1))))
      |> Enum.map(&({String.to_atom(&1), list_component_names(&1)}))
    end
  end

  @doc """
    Finds all folders within a section folder, and returns each folder's name as an atom
  """
  @spec list_component_names(String.t) :: [atom]
  defmacro list_component_names(section) do
    quote do
      path = Path.join(components_folder_path, unquote(section))

      path
      |> File.ls!
      |> Enum.filter(&(File.dir?(path <> "/" <> &1)))
      |> Enum.map(&(String.to_atom(&1)))
    end
  end

end

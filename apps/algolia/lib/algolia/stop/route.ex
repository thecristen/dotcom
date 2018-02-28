defmodule Algolia.Stop.Route do
  defstruct [:icon, :display_name]

  @type t :: %__MODULE__{
    icon: atom,
    display_name: String.t
  }

  @spec new(atom, [Routes.Route.t]) :: __MODULE__.t
  def new(icon, routes) do
    %__MODULE__{
      icon: icon,
      display_name: Routes.Route.type_summary(icon, routes)
    }
  end
end

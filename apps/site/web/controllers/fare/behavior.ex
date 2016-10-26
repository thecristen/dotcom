defmodule Site.FareController.Behavior do
  @moduledoc "Behavior for fare pages."

  @doc "The name of the template to render"
  @callback template() :: String.t

  @doc "Given a Plug.Conn, returns a list of fares for the page"
  @callback fares(Plug.Conn.t) :: [Fares.Fare.t]

  @doc "Given a list of Fares, returns the filters to use/display"
  @callback filters([Fares.Fare.t]) :: [Site.FareController.Filter.t]

  @doc "An optional callback to add additional data to the Plug.Conn"
  @callback before_render(Plug.Conn.t) :: Plug.Conn.t

  use Site.Web, :controller

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      def before_render(conn), do: conn

      defoverridable [before_render: 1]
    end
  end
end

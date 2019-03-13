defmodule SiteWeb.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      import SiteWeb.Router.Helpers
    end
  end

  setup do
    {:ok, session} = Wallaby.start_session()
    # Walllaby defaults to mobile screen size
    session_with_screen_size = Wallaby.Browser.resize_window(session, 1024, 768)
    {:ok, session: session_with_screen_size}
  end
end

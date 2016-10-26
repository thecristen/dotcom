defmodule Site.Router do
  use Site.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_cookies
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug BetaAnnouncement.Plug
    plug Turbolinks.Plug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Site do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/redirect/*path", RedirectController, :show
    resources "/stations", StationController, only: [:index, :show]
    get "/schedules", ModeController, :index
    get "/schedules/subway", ModeController, :subway
    get "/schedules/bus", ModeController, :bus
    get "/schedules/ferry", ModeController, :ferry
    get "/schedules/commuter", ModeController, :commuter
    get "/schedules/Green", ScheduleController.Green, :green
    get "/schedules/:route", ScheduleController, :show
    get "/style_guide", StyleGuideController, :index
    get "/style_guide/:section", StyleGuideController, :index
    get "/style_guide/:section/:component_group", StyleGuideController, :show
    resources "/alerts", AlertController, only: [:index, :show]
    get "/customer-support", CustomerSupportController, :index
    get "/customer-support/thanks", CustomerSupportController, :thanks
    post "/customer-support", CustomerSupportController, :submit
  end

  scope "/fares/", Site do
    pipe_through :browser

    get "/reduced", FareController, :reduced
    get "/charlie_card", FareController, :charlie_card
    get "/:id", FareController, :show
  end

  scope "/_flags", Laboratory do
    forward "/", Router
  end

  # Other scopes may use custom stacks.
  # scope "/api", Site do
  #   pipe_through :api
  # end
end

defmodule Site.Router do
  use Site.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
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
    get "/schedules/boat", ModeController, :boat
    get "/schedules/commuter-rail", ModeController, :commuter_rail
    get "/schedules/Green", ScheduleController.Green, :green
    get "/schedules/:route", ScheduleController, :show
    get "/alerts", AlertController, :index
    get "/customer-support", CustomerSupportController, :index
    get "/customer-support/thanks", CustomerSupportController, :thanks
    post "/customer-support", CustomerSupportController, :submit
    resources "/fares/commuter-rail", FareController, only: [:index]
  end

  scope "/_flags", Laboratory do
    forward "/", Router
  end

  # Other scopes may use custom stacks.
  # scope "/api", Site do
  #   pipe_through :api
  # end
end

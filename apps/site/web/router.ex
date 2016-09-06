defmodule Site.Router do
  use Site.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug BetaAnnouncement.Plug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Site do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/redirect/*path", RedirectController, :show
    resources "/stations", StationController, only: [:index, :show]
    get "/schedules/subway", ModeController, :subway
    get "/schedules/bus", ModeController, :bus
    get "/schedules/boat", ModeController, :boat
    get "/schedules/commuter-rail", ModeController, :commuter_rail
    get "/schedules", ScheduleController, :index
    get "/schedules/:route", ScheduleController, :index
    resources "/alerts", AlertController, only: [:index, :show]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Site do
  #   pipe_through :api
  # end
end

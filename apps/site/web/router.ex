defmodule Site.Router do
  use Site.Web, :router

  alias Site.StaticPage

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
    resources "/stops", StopController, only: [:index, :show]
    get "/schedules", ModeController, :index
    get "/schedules/subway", ModeController, :subway
    get "/schedules/bus", ModeController, :bus
    get "/schedules/ferry", ModeController, :ferry
    get "/schedules/commuter_rail", ModeController, :commuter_rail
    get "/schedules/Green", ScheduleController.Green, :green
    get "/schedules/:route", ScheduleController, :show
    get "/style_guide", StyleGuideController, :index
    get "/style_guide/:section", StyleGuideController, :index
    get "/style_guide/:section/:subpage", StyleGuideController, :show
    get "/service-near-me", ServiceNearMeController, :index
    resources "/alerts", AlertController, only: [:index, :show]
    get "/customer-support", CustomerSupportController, :index
    get "/customer-support/thanks", CustomerSupportController, :thanks
    post "/customer-support", CustomerSupportController, :submit
    resources "/fares", FareController, only: [:index, :show]
    resources "/how-to-pay", HowToPayController, only: [:index, :show], param: "mode"
    for static_page <- StaticPage.static_pages do
      get "/#{StaticPage.convert_path(static_page)}", StaticPageController, static_page
    end
  end


  scope "/_flags" do
    pipe_through [:browser]

    forward "/", Laboratory.Router
  end

  # This needs to go last so that it catches any URLs that fall through.
  scope "/" do
    pipe_through [:browser]

    forward "/", Content.Router
  end
end

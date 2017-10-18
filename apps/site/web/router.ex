defmodule Site.Router do
  use Site.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  alias Site.StaticPage

  pipeline :secure do
    if force_ssl = Application.get_env(:site, :secure_pipeline)[:force_ssl] do
      plug Plug.SSL, force_ssl
    end
  end

  pipeline :browser do
    plug SystemMetrics.Plug
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_cookies
    plug :put_secure_browser_headers
    plug Site.Plugs.Banner
    plug Turbolinks.Plug
    plug Site.Plugs.CommonFares
    plug Site.Plugs.Date
    plug Site.Plugs.DateTime
    plug Site.Plugs.RewriteUrls
    plug Site.Plugs.ClearCookies
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Site do
    # no pipe
    get "/_health", HealthController, :index
  end

  # redirect 't.mbta.com' and 'beta.mbta.com' to 'https://www.mbta.com'
  scope "/", Site, host: "t." do
    # no pipe
    get "/*path", WwwRedirector, []
  end
  scope "/", Site, host: "beta." do
    # no pipe
    get "/*path", WwwRedirector, []
  end

  scope "/", Site do
    pipe_through [:secure, :browser]

    # redirect underscored urls to hyphenated version
    get "/alerts/commuter_rail", Redirector, to: "/alerts/commuter-rail"
    get "/fares/bus_subway", Redirector, to: "/fares/bus-subway"
    get "/fares/charlie_card", Redirector, to: "/fares/charlie-card"
    get "/fares/commuter_rail", Redirector, to: "/fares/commuter-rail"
    get "/fares/commuter_rail/zone", Redirector, to: "/fares/commuter-rail/zone"
    get "/fares/payment_methods", Redirector, to: "/fares/payment-methods"
    get "/fares/retail_sales_locations", Redirector, to: "/fares/retail-sales-locations"
    get "/how-to-pay/commuter_rail", Redirector, to: "/how-to-pay/commuter-rail"
    get "/schedules/commuter_rail", Redirector, to: "/schedules/commuter-rail"
    get "/stops/commuter_rail", Redirector, to: "/stops/commuter-rail"
    get "/style_guide", Redirector, to: "/style-guide"
    get "/transit_near_me", Redirector, to: "/transit-near-me"
    get "/trip_planner", Redirector, to: "/trip-planner"

    # redirect SL and CT to proper route ids
    get "/schedules/SL1", Redirector, to: "/schedules/741"
    get "/schedules/sl1", Redirector, to: "/schedules/741"
    get "/schedules/SL2", Redirector, to: "/schedules/742"
    get "/schedules/sl2", Redirector, to: "/schedules/742"
    get "/schedules/SL4", Redirector, to: "/schedules/751"
    get "/schedules/sl4", Redirector, to: "/schedules/751"
    get "/schedules/SL5", Redirector, to: "/schedules/749"
    get "/schedules/sl5", Redirector, to: "/schedules/749"

    get "/schedules/CT1", Redirector, to: "/schedules/701"
    get "/schedules/ct1", Redirector, to: "/schedules/701"
    get "/schedules/CT2", Redirector, to: "/schedules/747"
    get "/schedules/ct2", Redirector, to: "/schedules/747"
    get "/schedules/CT3", Redirector, to: "/schedules/708"
    get "/schedules/ct3", Redirector, to: "/schedules/708"

    get "/", PageController, :index
    resources "/events", EventController, only: [:index, :show] do
      get "/icalendar", IcalendarController, :show
    end
    resources "/news", NewsEntryController, only: [:index, :show]
    resources "/projects", ProjectController, only: [:index, :show]
    get "/projects/:project_id/update/:id", ProjectController, :project_update
    get "/redirect/*path", RedirectController, :show
    get "/stops/Boat-George", Redirector, to: "/stops/ferry"
    resources "/stops", StopController, only: [:index, :show]
    get "/stops/*path", StopController, :stop_with_slash_redirect
    get "/schedules", ModeController, :index
    get "/schedules/subway", ModeController, :subway
    get "/schedules/bus", ModeController, :bus
    get "/schedules/ferry", ModeController, :ferry
    get "/schedules/commuter-rail", ModeController, :commuter_rail
    get "/schedules/Green/line", ScheduleV2Controller.Green, :line
    get "/schedules/Green/schedule", ScheduleV2Controller.Green, :trip_view
    get "/schedules/Green", ScheduleV2Controller.Green, :show
    get "/schedules/:route/timetable", ScheduleV2Controller.TimetableController, :show, as: :timetable
    get "/schedules/:route/schedule", ScheduleV2Controller.TripViewController, :show, as: :trip_view
    get "/schedules/:route/line", ScheduleV2Controller.LineController, :show, as: :line
    get "/schedules/:route", ScheduleV2Controller, :show, as: :schedule
    get "/schedules/:route/pdf", ScheduleV2Controller.Pdf, :pdf, as: :route_pdf
    get "/style-guide", StyleGuideController, :index
    get "/style-guide/:section", StyleGuideController, :index
    get "/style-guide/:section/:subpage", StyleGuideController, :show
    get "/transit-near-me", TransitNearMeController, :index
    resources "/alerts", AlertController, only: [:index, :show]
    get "/trip-planner", TripPlanController, :index
    get "/customer-support", CustomerSupportController, :index
    get "/customer-support/thanks", CustomerSupportController, :thanks
    post "/customer-support", CustomerSupportController, :submit
    get "/fares/commuter-rail/zone", FareController, :zone
    resources "/fares", FareController, only: [:index, :show]
    resources "/how-to-pay", HowToPayController, only: [:index, :show], param: "mode"
    get "/search", SearchController, :index
    for static_page <- StaticPage.static_pages do
      get "/#{StaticPage.convert_path(static_page)}", StaticPageController, static_page
    end
  end

  #static files
  scope "/", Site do
    pipe_through [:secure, :browser]
    get "/sites/*path", StaticFileController, :index
  end

  #old site
  scope "/", Site do
    pipe_through [:secure, :browser]

    get "/schedules_and_maps", OldSiteRedirectController, :schedules_and_maps
    get "/schedules_and_maps/*path", OldSiteRedirectController, :schedules_and_maps
    get "/about_the_mbta/public_meetings", Redirector, to: "/events"
    get "/about_the_mbta/news_events", Redirector, to: "/news"
  end

  #old site static files
  scope "/", Site do
    pipe_through [:secure]
    get "/uploadedfiles/*path", OldSiteRedirectController, :uploaded_files
    get "/uploadedFiles/*path", OldSiteRedirectController, :uploaded_files
    get "/uploadedimages/*path", OldSiteRedirectController, :uploaded_files
    get "/uploadedImages/*path", OldSiteRedirectController, :uploaded_files
    get "/images/*path", OldSiteRedirectController, :uploaded_files
    get "/lib/*path", OldSiteRedirectController, :uploaded_files
    get "/gtfs_archive/archived_feeds.txt", OldSiteRedirectController, :archived_files
  end

  scope "/_flags" do
    pipe_through [:secure, :browser]

    forward "/", Laboratory.Router
  end

  scope "/", Site do
    pipe_through [:secure, :browser]

    get "/*path", ContentController, :page
  end
end

defmodule SiteWeb.CustomerSupportController do
  use SiteWeb, :controller

  plug Turbolinks.Plug.NoCache
  plug :set_service_options

  def index(conn, _params) do
    render_form conn, []
  end

  def thanks(conn, _params) do
    render conn,
      "index.html",
      breadcrumbs: [Breadcrumb.build("Customer Support")],
      show_form: false
  end

  defp render_form(conn, errors) do
    render conn,
      "index.html",
      breadcrumbs: [Breadcrumb.build("Customer Support")],
      errors: errors,
      show_form: true
  end

  defp set_service_options(conn, _) do
    assign(conn, :service_options, Feedback.Message.service_options())
  end
end

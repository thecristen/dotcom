defmodule SiteWeb.CustomerSupportControllerTest do
  use SiteWeb.ConnCase

  describe "GET" do
    test "shows the support form", %{conn: conn} do
      conn = get conn, customer_support_path(conn, :index)
      response = html_response(conn, 200)
      assert response =~ "Customer Support"
    end

    test "sets the service options on the connection", %{conn: conn} do
      conn = get conn, customer_support_path(conn, :index)

      assert conn.assigns.service_options == Feedback.Message.service_options
    end
  end
end

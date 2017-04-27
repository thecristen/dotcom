defmodule Site.CustomerSupportControllerTest do
  use Site.ConnCase, async: true

  describe "GET" do
    test "shows the support form", %{conn: conn} do
      conn = get conn, customer_support_path(conn, :index)
      response = html_response(conn, 200)
      assert response =~ "Customer Support"
    end
  end

  describe "POST" do
    def valid_request_response_data do
      %{"comments" => "comments", "email" => "test@gmail.com", "privacy" => "on", "phone" => "", "name" => "tom brady", "request_response" => "on"}
    end

    def valid_no_response_data do
      %{"comments" => "comments", "request_response" => "off"}
    end

    test "shows a thank you message on success and sends an email", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), valid_request_response_data()
      response = html_response(conn, 302)
      refute response =~ "form id=\"support-form\""
      assert redirected_to(conn) == customer_support_path(conn, :thanks)
      assert String.contains?(Feedback.Test.latest_message["text"], ~s(<MBTASOURCE>Auto Ticket 2</MBTASOURCE>))
    end

    test "validates presence of comments", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_request_response_data(), "comments", "")
      assert "comments" in conn.assigns.errors
    end

    test "does not require name if customer does not want a response", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_no_response_data(), "name", "")
      refute conn.assigns["errors"]
    end

    test "requires name if customer does want a response", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_request_response_data(), "name", "")
      assert "name" in conn.assigns.errors
    end

    test "does not require email or phone when the customer wants a response", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_no_response_data(), "email", "")
      refute conn.assigns["errors"]
    end

    test "invalid with no email or phone when the customer wants a response", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_request_response_data(), "email", "")
      assert "contacts" in conn.assigns.errors
    end

    test "requires a real email", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_request_response_data(), "email", "not an email")
      assert "contacts" in conn.assigns.errors
    end

    test "valid with a phone number", %{conn: conn} do
      conn = post conn,
        customer_support_path(conn, :submit),
        Map.merge(valid_request_response_data(), %{"email" => "", "phone" => "555-555-5555"})
      refute html_response(conn, 302) =~ "form id=\"support-form\""
      assert redirected_to(conn) == customer_support_path(conn, :thanks)
    end

    test "does not require privacy checkbox when customer does not want a response", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_no_response_data(), "privacy", "")
      refute conn.assigns["errors"]
    end

    test "requires privacy checkbox when customer wants a response", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_request_response_data(), "privacy", "")
      assert "privacy" in conn.assigns.errors
    end
  end
end

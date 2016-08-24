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
    def valid_post_data do
      %{"comments" => "comments", "email" => "test@gmail.com", "privacy" => "on", "phone" => "", "name" => ""}
    end

    test "shows a thank you message on success and sends an email", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), valid_post_data
      response = html_response(conn, 302)
      refute response =~ "form id=\"support-form\""
      assert redirected_to(conn) == customer_support_path(conn, :thanks)
      assert String.contains?(Feedback.Test.latest_message["text"], "Additional Comments: comments\n")
    end

    test "validates presence of comments", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_post_data, "comments", "")
      assert "comments" in conn.assigns.errors
    end

    test "invalid with no email or phone", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_post_data, "email", "")
      assert "contacts" in conn.assigns.errors
    end

    test "requires a real email", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_post_data, "email", "not an email")
      assert "contacts" in conn.assigns.errors
    end

    test "valid with a phone number", %{conn: conn} do
      conn = post conn,
        customer_support_path(conn, :submit),
        Map.merge(valid_post_data, %{"email" => "", "phone" => "555-555-5555"})
      refute html_response(conn, 302) =~ "form id=\"support-form\""
      assert redirected_to(conn) == customer_support_path(conn, :thanks)
    end

    test "validates presence of privacy checkbox", %{conn: conn} do
      conn = post conn, customer_support_path(conn, :submit), Map.put(valid_post_data, "privacy", "")
      assert "privacy" in conn.assigns.errors
    end
  end
end

defmodule Content.RouterTest do
  use ExUnit.Case, async: true

  import Content.Router
  import Plug.Conn

  @doc "Used as a test version of the :page handler for content."
  def test_page(conn, page) do
    conn
    |> put_private(:page, page)
  end

  describe "match/2 + dispatch/2" do
    setup do
      old_mfa = Application.get_env(:content, :mfa)
      new_mfa = put_in old_mfa[:page], {__MODULE__, :test_page, []}
      Application.put_env(:content, :mfa, new_mfa)
      on_exit fn ->
        Application.put_env(:content, :mfa, old_mfa)
      end
      :ok
    end
    test "doesn't crash when given an OPTIONS request" do
      conn = %{build_conn() | method: :options}
      response = conn
      |> match([])
      |> dispatch([])
      assert {:error, _} = response.private.page
    end
  end

  describe "forward_response/2" do
    test "returns a 404 if there's an error" do
      response = forward_response(build_conn, {:error, "something"})
      assert response.status == 404
      assert response.state == :sent
    end

    test "returns a 404 if the remote side returned a 404" do
      response = forward_response(build_conn, {:ok, %HTTPoison.Response{status_code: 404}})
      assert response.status == 404
      assert response.state == :sent
    end

    test "returns the body and headers from the response if it's a 200" do
      remote_response = %HTTPoison.Response{
        status_code: 200,
        body: "body",
        headers: [{"Content-Type", "text/plain"},
                  {"ETag", "tag"},
                  {"Date", "date"},
                  {"Content-Length", "5"}]
      }
      response = forward_response(build_conn, {:ok, remote_response})
      assert response.status == 200
      assert response.resp_body == remote_response.body
      assert get_resp_header(response, "content-type") == ["text/plain"]
      assert get_resp_header(response, "etag") == ["tag"]
      assert get_resp_header(response, "date") == ["date"]
      refute get_resp_header(response, "content-length") == ["5"]
    end
  end

  defp build_conn do
    Plug.Adapters.Test.Conn.conn(%Plug.Conn{}, :get, "/", "")
  end
end

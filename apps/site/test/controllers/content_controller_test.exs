defmodule ContentControllerTest do
  use Site.ConnCase
  import Mock

  @page %Content.Page{
    body: "Stay safe this winter",
    title: "News Title",
    type: "news_entry",
    updated_at: DateTime.utc_now,
    fields: %{
      featured_image: %Content.Page.Image{
        alt: "alt",
        url: "image_url",
      }
    }
  }

  describe "GET - page" do
    test "renders a news entry when the CMS returns the content type: news_entry", %{conn: conn} do
      with_mock Content.Repo, [page: fn(_path, _params) -> {:ok, @page} end] do
        conn = get conn, "existing-news-entry"
        assert html_response(conn, 200) =~ @page.title
      end
    end

    test "renders a 404 when the CMS returns an error", %{conn: conn} do
      with_mock Content.Repo, [page: fn(_path, _params) -> {:error, "error message"} end] do
        conn = get conn, "unknown-path-for-content"
        assert html_response(conn, 404)
      end
    end

    test "renders a 404 when any other error occurs", %{conn: conn} do
      with_mock Content.Repo, [page: fn(_path, _params) -> "whoops" end] do
        conn = get conn, "something-went-wrong"
        assert html_response(conn, 404)
      end
    end
  end
end

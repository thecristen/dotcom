defmodule Site.ErrorViewTest do
  use Site.ConnCase, async: true

  import Phoenix.View, only: [render_to_string: 3]
  import Phoenix.Controller

  test "adds 'not-found' to body class on 404 pages" do
    conn = get build_conn(), "/not-found"
    assert html_response(conn, 404) =~ "not-found"
  end

  test "renders 404.html" do
    expected = "This page is no longer in service"
    actual = render_to_string(Site.ErrorView, "404.html", [])
    assert actual =~ expected
  end

  test "render 500.html" do
    assert render_to_string(Site.ErrorView, "500.html", []) =~ "It looks like we have our signals crossed"
  end

  test "render any other" do
    assert render_to_string(Site.ErrorView, "505.html", []) =~ "It looks like we have our signals crossed"
  end

  test "render 500.html with a layout", %{conn: conn} do
    # mimick the pipeline RenderErrors
    conn = conn
    |> accepts(["html"])
    |> put_private(:phoenix_endpoint, Site.Endpoint)
    |> put_layout({Site.LayoutView, "app.html"})
    |> put_view(Site.ErrorView)
    |> put_status(500)
    |> render(:"500", %{})

    assert html_response(conn, 500) =~ "signals crossed"
  end
end

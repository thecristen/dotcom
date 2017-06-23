defmodule Site.LayoutViewTest do
  use Site.ConnCase, async: true

  import Phoenix.HTML

  import Site.LayoutView

  describe "bold_if_active/3" do
    test "bold_if_active makes text bold if the current request is made against the given path", %{conn: conn} do
      conn = %{conn | request_path: "/schedules/subway"}
      assert bold_if_active(conn, "/schedules", "test") == raw("<strong>test</strong>")
    end

    test "bold_if_active only makes text bold if the current request is made to root path", %{conn: conn} do
      conn = %{conn | request_path: "/"}
      assert bold_if_active(conn, "/", "test") == raw("<strong>test</strong>")
      assert bold_if_active(conn, "/schedules", "test") == raw("test")
    end
  end

  test "renders breadcrumbs in the title", %{conn: conn} do
    conn = get conn, "/schedules/subway"
    body = html_response(conn, 200)

    expected_title = "Subway < Schedules & Maps < MBTA - Massachusetts Bay Transportation Authority"
    assert body =~ "<title>#{expected_title}</title>"
  end

  test "beta announcement links the feedback form", %{conn: conn} do
    conn = get conn, "/"
    body = conn
           |> html_response(200)
           |> Floki.find(".beta-announcement-link")
           |> Floki.attribute("href")

    assert body == [Site.ViewHelpers.feedback_form_url()]
  end

  describe "_header.html" do
    test "renders desktop nav with all content drawers", %{conn: conn} do
      assert {:safe, html} = render("_header.html", %{conn: conn})
      assert [{"nav", _, drawers}] = html |> IO.iodata_to_binary() |> Floki.find("#desktop-menu")
      refute Floki.raw_html(drawers) =~ "mobile"
      assert conn |> nav_link_content() |> length() > 0

      conn
      |> nav_link_content()
      |> Enum.each(fn {name, description, icon, href} ->

        camelized = Site.ViewHelpers.to_camelcase(name)
        id = "#" <> camelized

        assert [{"div", _, drawer_content}] = Floki.find(drawers, id)
        assert [{"a", link_attrs, link_content}] = Floki.find(drawers, ".desktop-nav-link[href=\"#{href}\"]")
        assert Floki.raw_html(link_content) =~ icon |> Atom.to_string() |> String.replace("_", "-")
        assert [controls, expanded, _class, parent, target, toggle, _href, role] = link_attrs

        assert controls == {"aria-controls", camelized}
        assert expanded == {"aria-expanded", "false"}
        assert parent == {"data-parent", "#desktop-menu"}
        assert toggle == {"data-toggle", "collapse"}
        assert target == {"data-target", id}
        assert role == {"role", "tab"}

        refute Floki.raw_html(drawer_content) =~ description

        if id == "#fares" do
          assert [{"div", _, _}] = Floki.find(drawer_content, ".fare-summary-container")
        end
      end)
    end

    test "renders mobile nav with all content drawers", %{conn: conn} do
      assert {:safe, html} = render("_header.html", %{conn: conn})
      html_string = IO.iodata_to_binary(html)
      conn
      |> nav_link_content()
      |> Enum.each(fn {name, description, _icon, link} ->
        assert html_string =~ name
        assert html_string =~ description
        assert html_string =~ link
      end)
    end
  end
end

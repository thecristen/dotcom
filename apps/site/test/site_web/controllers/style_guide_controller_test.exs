defmodule SiteWeb.StyleGuideControllerTest do
  use Site.Components.Register
  use SiteWeb.ConnCase, async: true

  test "all known pages render", %{conn: conn} do
    for {section_atom, subpages} <- SiteWeb.StyleGuideController.known_pages() do
      section_string = section_atom |> Atom.to_string() |> String.replace("_", "-")
      conn = get conn, "style-guide/#{section_string}"
      assert Enum.member?([200, 302], conn.status)
      for subpage_atom <- subpages do
        subpage_string = subpage_atom |> Atom.to_string() |> String.replace("_", "-")
        conn = get conn, "style-guide/#{section_string}/#{subpage_string}"
        assert html_response(conn, 200)
      end
    end
  end

  test "`use Site.Components.Register` registers a list of component groups which each have a list of components" do
    @components
    |> Enum.each(fn {group, components} ->
      assert is_atom(group) == true
      Enum.each(components, fn component ->
        assert is_atom(component) == true
      end)
    end)
  end

  test "@components gets assigned to conn when visiting /style-guide/*", %{conn: conn} do
    assigned_components =
      conn
      |> bypass_through(:browser)
      |> get("/style-guide")
      |> Map.get(:assigns)
      |> Map.get(:components)

    assert @components == assigned_components
  end

  test "component pages in style guide do not cause 500 errors", %{conn: conn} do
    @components
    |> Enum.map(&get_component_section_conn(conn, &1))
    |> Enum.each(&(assert &1.status == 200))
  end

  test "/style-guide/content redirects to /style-guide/content/audience_goals_tone", %{conn: conn} do
    conn = get conn, "style-guide/content"
    assert html_response(conn, 302) =~ "/style-guide/content/audience-goals-tone"
  end

  test "/style-guide/components/* has a side navbar", %{conn: conn} do
    conn = get conn, "/style-guide/components/typography"
    assert html_response(conn, 200) =~ "subpage-nav"
  end

  test "/style-guide/content/* has a side navbar", %{conn: conn} do
    conn = get conn, "/style-guide/content/terms"
    assert html_response(conn, 200) =~ "subpage-nav"
  end

  ###########################
  # HELPER FUNCTIONS
  ###########################

  def get_component_section_conn(conn, {section, _components}) do
    conn
    |> bypass_through(:browser)
    |> get("/style-guide/components/#{section}")
  end

end

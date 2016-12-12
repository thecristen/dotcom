defmodule Site.StyleGuideControllerTest do
  use Site.Components.Register
  use Site.ConnCase, async: true

  test "all known pages render", %{conn: conn} do
    for {section_name, subpages} <- Site.StyleGuideController.known_pages() do
      conn = get conn, "style_guide/#{section_name}"
      valid = case conn.status do
        200 -> true
        302 -> true
        _ -> false
      end
      assert valid == true
      for subpage <- subpages do
        conn = get conn, "style_guide/#{section_name}/#{subpage}"
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

  test "@components gets assigned to conn when visiting /style_guide/*" do
    assigned_components =
      build_conn
      |> bypass_through(:browser)
      |> get("/style_guide")
      |> Map.get(:assigns)
      |> Map.get(:components)

    assert @components == assigned_components
  end

  test "component pages in style guide do not cause 500 errors" do
    @components
    |> Enum.map(&get_component_section_conn/1)
    |> Enum.each(&(assert %{conn: %{status: 200}} = &1))
  end

  test "/style_guide/content redirects to /style_guide/content/audience_goals_tone", %{conn: conn} do
    conn = get conn, "style_guide/content"
    assert html_response(conn, 302) =~ "/style_guide/content/audience_goals_tone"
  end

  test "/style_guide/components/* has a side navbar", %{conn: conn} do
    conn = get conn, "/style_guide/components/typography"
    assert html_response(conn, 200) =~ "subpage-nav"
  end

  test "/style_guide/content/* has a side navbar", %{conn: conn} do
    conn = get conn, "/style_guide/content/terms"
    assert html_response(conn, 200) =~ "subpage-nav"
  end

  ###########################
  # HELPER FUNCTIONS
  ###########################

  def get_component_section_conn({section, components}) do
    conn = build_conn
    |> bypass_through(:browser)
    |> get("/style_guide/components/#{section}")
    %{conn: conn, section: section, components: components}
  end

end

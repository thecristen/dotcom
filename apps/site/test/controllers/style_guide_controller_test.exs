defmodule Site.StyleGuideControllerTest do
  use Site.Components.Register
  use Site.ConnCase, async: true

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

defmodule Site.StyleGuideController do
  use Site.Web, :controller
  use Site.Components.Register
  use Phoenix.HTML

  # need to declare known sections and subpages to ensure that String.to_existing_atom works
  @spec known_pages :: keyword
  @doc "A keyword list of all known pages in the styleguide section."
  def known_pages do
    [
      components: [:typography, :colors, :logo | Keyword.keys(@components)],
      content: [:audience_goals_tone, :grammar_and_mechanics, :terms],
      principles: [],
      about: []
    ]
  end

  def index(conn, %{"section" => "content"}) do
    redirect conn, to: "/style_guide/content/audience_goals_tone"
  end
  def index(conn, %{"section" => "components"}) do
    redirect conn, to: "/style_guide/components/typography"
  end
  def index(conn, %{"section" => _} = params), do: render_section(conn, params)

  def index(conn, params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("index.html")
  end

  defp render_section(conn, %{"section" => section} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("#{section}.html")
  end

  def show(conn, %{"subpage" => "typography"} = params), do: render_subpage(conn, params)
  def show(conn, %{"subpage" => "colors"} = params), do: render_subpage(conn, params)
  def show(conn, %{"subpage" => "logo"} = params), do: render_subpage(conn, params)
  def show(conn, %{"section" => "content", "subpage" => _} = params), do: render_subpage(conn, params)
  def show(conn, %{"subpage" => component_group} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> assign(:section_components, get_components(component_group))
    |> render("show.html")
  end

  defp render_subpage(conn, %{"subpage" => subpage} = params) do
    conn
    |> assign_styleguide_conn(params)
    |> render("_#{subpage}.html")
  end

  defp assign_styleguide_conn(conn, %{"subpage" => subpage} = params) do
    conn
    |> styleguide_conn(params)
    |> assign_all_subpages(params)
    |> assign(:subpage, String.to_existing_atom(subpage))
  end

  defp assign_styleguide_conn(conn, params) do
    conn
    |> styleguide_conn(params)
  end

  defp styleguide_conn(conn, %{"section" => section}) do
    conn
    |> styleguide_layout
    |> assign(:section, String.to_existing_atom(section))
  end

  defp styleguide_conn(conn, _) do
    conn
    |> styleguide_layout
    |> assign(:section, nil)
  end

  defp styleguide_layout(conn) do
    conn
    |> put_layout("style_guide.html")
    |> assign(:components, @components)
  end

  @spec get_components(String.t) :: [atom]
  defp get_components(group) do
    group_atom = String.to_existing_atom(group)
    @components
    |> Enum.find(&match?({^group_atom, _}, &1))
    |> elem(1)
  end

  defp assign_all_subpages(conn, %{"section" => section}) do
    conn
    |> assign(:all_subpages, Keyword.get(known_pages(), String.to_existing_atom(section)))
  end

end

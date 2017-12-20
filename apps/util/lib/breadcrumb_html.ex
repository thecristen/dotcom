defmodule Util.BreadcrumbHTML do
  import Phoenix.HTML, only: [raw: 1]

  @spec breadcrumb_trail(%Plug.Conn{}) :: Phoenix.HTML.safe
  def breadcrumb_trail(%Plug.Conn{assigns: %{breadcrumbs: []}}), do: raw("")
  def breadcrumb_trail(%Plug.Conn{assigns: %{breadcrumbs: breadcrumbs}} = conn) do
    breadcrumbs
    |> maybe_add_home_breadcrumb()
    |> build_html(conn)
    |> Enum.join("")
    |> raw()
  end
  def breadcrumb_trail(%Plug.Conn{}), do: raw("")

  @spec build_html([%Util.Breadcrumb{}], %Plug.Conn{}) :: [String.t]
  def build_html(breadcrumbs, conn) do
    crumbs = indexed_crumbs_ordered_by_current_to_home(breadcrumbs)

    html = Enum.map(crumbs, fn({crumb, index}) ->
      cond do
        current_breadcrumb?(index) ->
          breadcrumb_link(crumb, conn)
        crumb_proceeding_current_breadcrumb(index) ->
          generate_html(crumb, %{icon: fa_icon()}, conn)
        true ->
          generate_html(
            crumb,
            %{class: hide_on_mobile_class(), icon: fa_icon()},
            conn
          )
      end
    end)

    Enum.reverse(html)
  end

  defp indexed_crumbs_ordered_by_current_to_home(breadcrumbs) do
    breadcrumbs
    |> Enum.reverse()
    |> Enum.with_index()
  end

  defp current_breadcrumb?(index) do
    index == 0
  end

  defp crumb_proceeding_current_breadcrumb(index) do
    index == 1
  end

  @spec title_breadcrumbs(%Plug.Conn{}) :: Phoenix.HTML.Safe.t
  def title_breadcrumbs(%Plug.Conn{assigns: %{breadcrumbs: breadcrumbs}}) when is_list(breadcrumbs) do
    breadcrumbs
    |> Enum.map(fn(breadcrumb) -> breadcrumb.text end)
    |> Enum.reverse([default_title()]) # put the default title at the end
    |> Enum.intersperse(" < ")
  end
  def title_breadcrumbs(%Plug.Conn{}) do
    default_title()
  end

  defp default_title do
    "MBTA - Massachusetts Bay Transportation Authority"
  end

  defp generate_html(breadcrumb, options, conn) do
    open_span_tag(options[:class]) <>
    breadcrumb_link(breadcrumb, conn) <>
    icon_html(options[:icon]) <>
    ~s(</span>)
  end

  defp breadcrumb_link(breadcrumb, conn) do
    if breadcrumb.url != "" do
      breadcrumb.text
      |> Phoenix.HTML.Link.link(to: check_preview(conn, breadcrumb.url))
      |> Phoenix.HTML.safe_to_string()
    else
      breadcrumb.text
    end
  end

  def check_preview(%{query_params: %{"preview" => nil, "vid" => _}}, path = "/" <> _internal) do
    path <> "?preview&vid=latest"
  end
  def check_preview(_conn, path), do: path

  defp fa_icon, do: ~s(fa fa-angle-right)

  defp icon_html(nil), do: ""
  defp icon_html(icon), do: ~s(<i class="#{icon}" aria-hidden="true"></i>)

  defp open_span_tag(nil), do: ~s(<span>)
  defp open_span_tag(css_class), do: ~s(<span class="#{css_class}">)

  defp hide_on_mobile_class, do: ~s(focusable-sm-down)

  @spec maybe_add_home_breadcrumb([%Util.Breadcrumb{}]) :: [%Util.Breadcrumb{}]
  def maybe_add_home_breadcrumb(breadcrumbs) do
    if missing_home_breadcrumb?(breadcrumbs) do
      home = %Util.Breadcrumb{url: "/", text: "Home"}
      [home | breadcrumbs]
    else
      breadcrumbs
    end
  end

  defp missing_home_breadcrumb?([]), do: true
  defp missing_home_breadcrumb?(breadcrumbs) do
    first_breadcrumb = List.first(breadcrumbs)
    first_breadcrumb.url != "/"
  end
end

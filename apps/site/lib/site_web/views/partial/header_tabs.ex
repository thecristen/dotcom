defmodule SiteWeb.PartialView.HeaderTabs do
  use SiteWeb, :view

  def render_tabs(tabs, selected, btn_class \\ "") do
    content_tag :div, class: "header-tabs" do
      for {id, name, href} <- tabs do
        render_tab(name, href, id == selected, btn_class)
      end
    end
  end

  def render_tab(name, href, selected, class) do
    Phoenix.HTML.Link.link to: href,
                           id: slug(name),
                           class: "header-tab #{selected_class(selected)} #{class}" do
      name
    end
  end

  def selected_class(true), do: "header-tab--selected"
  def selected_class(false), do: ""
end

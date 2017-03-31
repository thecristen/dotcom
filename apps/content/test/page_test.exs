defmodule Content.PageTest do
  use ExUnit.Case, async: true

  alias Content.CMS.Static

  describe "from_api/1" do
    test "switches on the node type in the json response and returns the proper page struct" do
      assert %Content.BasicPage{} = Content.Page.from_api(Static.basic_page_response())
      assert %Content.NewsEntry{} = Content.Page.from_api(List.first(Static.recent_news_response()))
      assert %Content.ProjectUpdate{} = Content.Page.from_api(Static.project_update_response())
    end
  end
end

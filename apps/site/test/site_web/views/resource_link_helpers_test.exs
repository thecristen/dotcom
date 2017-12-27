defmodule SiteWeb.EventHelpersTest do
  @moduledoc false
  use SiteWeb.ConnCase, async: true

  import SiteWeb.ResourceLinkHelpers

  describe "show_path/2" do
    test "handles event" do
      assert show_path(:event, "19") == "/events/19"
    end

    test "handles event with a slash in the name" do
      assert show_path(:event, "april-12-2017/board_meeting") == "/events/april-12-2017/board_meeting"
    end

    test "handles news" do
      assert show_path(:news, "19") == "/news/19"
    end

    test "handles news with a slash in the name" do
      assert show_path(:news, "april-12-2017/board_meeting") == "/news/april-12-2017/board_meeting"
    end

    test "handles project" do
      assert show_path(:project, "19") == "/projects/19"
    end

    test "handles project with a slash in the name" do
      assert show_path(:project, "april-12-2017/board_meeting") == "/projects/april-12-2017/board_meeting"
    end
  end
end

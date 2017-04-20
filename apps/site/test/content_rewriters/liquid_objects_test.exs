defmodule Site.ContentRewriters.LiquidObjectsTest do
  use ExUnit.Case, async: true

  import Site.ContentRewriters.LiquidObjects
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ContentView, only: [svg_icon_with_circle: 1]
  import Site.ViewHelpers, only: [fa: 1]

  alias Site.Components.Icons.SvgIconWithCircle

  describe "replace/1" do
    test "it replaces fa- prefixed objects" do
      assert replace(~s(fa "xyz")) == safe_to_string(fa("xyz"))
      assert replace(~s(fa "abc")) == safe_to_string(fa("abc"))
    end

    test "it replaces an mbta icon" do
      assert replace(~s(mbta-circle-icon "subway")) == make_svg(:subway)
      assert replace(~s(mbta-circle-icon "commuter-rail")) == make_svg(:commuter_rail)
      assert replace(~s(mbta-circle-icon "bus")) == make_svg(:bus)
      assert replace(~s(mbta-circle-icon "ferry")) == make_svg(:ferry)
      assert replace(~s(mbta-circle-icon "t-logo")) == make_t_logo()
    end

    test "it handles unknown mbta icons" do
      assert replace(~s(mbta-circle-icon "unknown")) == ~s({{ mbta-circle-icon "unknown" }})
    end

    test "it returns liquid object when not otherwise handled" do
      assert replace("something-else") == "{{ something-else }}"
    end
  end

  defp make_svg(mode) do
    %SvgIconWithCircle{icon: mode}
    |> svg_icon_with_circle
    |> safe_to_string
  end

  defp make_t_logo do
    %SvgIconWithCircle{icon: :t_logo, class: "icon-boring"}
    |> svg_icon_with_circle
    |> safe_to_string
  end
end

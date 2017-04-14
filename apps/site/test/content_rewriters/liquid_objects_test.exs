defmodule Site.ContentRewriters.LiquidObjectsTest do
  use ExUnit.Case, async: true

  import Site.ContentRewriters.LiquidObjects
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ViewHelpers, only: [fa: 1]

  describe "replace/1" do
    test "it replaces fa- prefixed objects" do
      assert replace(~s(fa "xyz")) == safe_to_string(fa("xyz"))
      assert replace(~s(fa "abc")) == safe_to_string(fa("abc"))
    end

    test "it returns an empty string when not fa- prefixed" do
      assert replace("something-else") == "{{ something-else }}"
    end
  end
end

defmodule CSSHelpersTest do
  use ExUnit.Case

  import CSSHelpers

  describe "atom_to_class/1" do
    test "converts the atom to a dash delimted string" do
      assert atom_to_class(:the_ride) == "the-ride"
      assert atom_to_class(:subway) == "subway"
      assert atom_to_class(:commuter_rail) == "commuter-rail"
      assert atom_to_class(:has_multiple_words) == "has-multiple-words"
    end
  end
end

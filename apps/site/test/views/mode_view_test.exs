defmodule Site.ModeViewTest do
  use ExUnit.Case, async: true

  import Site.ModeView
  import Phoenix.HTML, only: [safe_to_string: 1]
  
  describe "fares_note/1" do
    test "Commuter Rail has note" do
      commuter_note = fares_note("Commuter Rail")
      commuter_text = "Commuter Rail fares are separated"
      assert safe_to_string(commuter_note) =~ commuter_text
      refute safe_to_string(fares_note("Ferry")) =~ commuter_text
    end
  end
end

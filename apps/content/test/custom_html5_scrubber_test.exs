defmodule Content.CustomHTML5ScrubberTest do
  use ExUnit.Case, async: true
  import Content.CustomHTML5Scrubber

  test "allows the mailto URI scheme" do
    html = "Please email <a href=\"mailto:AACT@ctps.org\">AACT@ctps.org</a>"
    assert html5(html) == html
  end
end

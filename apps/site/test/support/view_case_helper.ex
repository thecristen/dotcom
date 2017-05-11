defmodule Site.ViewCaseHelper do
  import ExUnit.Assertions

  def refute_text_visible?(html, text) do
    refute html =~ text
    html
  end
end

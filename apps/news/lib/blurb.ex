defmodule News.Blurb do
  def blurb("<p>" <> _ = text) do
    # find the first paragraph that doesn't contain "Media Contact"
    text
    |> String.split(["<p>", "</p>"])
    |> Enum.reject(fn paragraph ->
      paragraph =~ ~R(Media Contact)
    end)
    |> Enum.reject(fn paragraph ->
      String.strip(paragraph) == ""
    end)
    |> List.first
    |> blurb
  end
  def blurb(text) when byte_size(text) > 70 do
    text
    |> String.strip
    |> String.slice(0..70)
    |> Kernel.<>("...")
  end
  def blurb(text) do
    text
  end
end

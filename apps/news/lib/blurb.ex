defmodule News.Blurb do
  def max_length do
    90
  end

  def suffix do
    "..."
  end

  def blurb("<p>" <> _ = text) do
    # find the first paragraph that doesn't contain "Media Contact" or "By"
    text
    |> String.split("<p>")
    |> Enum.reject(fn paragraph ->
      paragraph =~ ~R"Media Contact|^(?>\s|&nbsp;|&#160;)*By "
    end)
    |> Enum.map(fn paragraph ->
      # remove a trailing </p>
      paragraph |> String.split("</p") |> List.first
    end)
    |> Enum.reject(fn paragraph ->
      # remove empty paragraphs
      String.strip(paragraph) == ""
    end)
    |> List.first
    |> blurb
  end
  def blurb(nil) do
    ""
  end
  def blurb(text) do
    text = text
    |> String.replace(~R(<br.*?>), " ")
    |> HtmlSanitizeEx.strip_tags

    if String.length(text) > max_length() do
      blurb_length = max_length() - String.length(suffix())
      text
      |> String.strip
      |> String.slice(Range.new(0, blurb_length - 1))
      |> Kernel.<>(suffix())
    else
      text
    end
  end
end

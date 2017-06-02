defmodule Content.CmsMigration.NewsEntryPayload do
  alias Content.CmsMigration.DataNormalizer
  alias Content.CmsMigration.Datetime

  @former_mbta_host Application.get_env(:site, :former_mbta_site)[:host]

  @spec build(map) :: map | no_return
  def build(map) do
    map
    |> build_news_entry()
    |> format_for_cms()
  end

  defp build_news_entry(map) do
    %Content.NewsEntry{
      title: title(map),
      body: body(map),
      teaser: teaser(map),
      media_contact: media_contact(map),
      media_phone: media_phone(map),
      media_email: media_email(map),
      posted_on: posted_on(map),
      migration_id: migration_id(map)
    }
  end

  defp format_for_cms(news_entry) do
    %{
      title: cms_format(news_entry.title),
      body: cms_format_body(news_entry.body),
      field_teaser: cms_format(news_entry.teaser),
      field_media_contact: cms_format(news_entry.media_contact),
      field_media_phone: cms_format(news_entry.media_phone),
      field_media_email: cms_format(news_entry.media_email),
      field_posted_on: cms_format(news_entry.posted_on),
      field_migration_id: cms_format(news_entry.migration_id),
      type: [%{"target_id": "news_entry"}]
    }
  end

  defp title(%{"title" => title}) do
    HtmlSanitizeEx.strip_tags(title)
  end

  defp body(%{"information" => body}) do
    body
    |> DataNormalizer.update_relative_links("uploadedfiles", @former_mbta_host)
    |> DataNormalizer.update_relative_image_paths("uploadedimages", @former_mbta_host)
    |> DataNormalizer.remove_style_information()
  end

  defp teaser(%{"information" => body}) do
    teaser_maximum_length = 255
    Content.Blurb.blurb(body, teaser_maximum_length, "Continue reading...")
  end

  defp media_contact(%{"contact_name" => name}), do: name

  defp media_phone(%{"phone" => phone}), do: phone

  defp media_email(%{"email" => email}), do: String.trim(email)

  defp posted_on(%{"event_date" => date}) do
    date
    |> Datetime.parse_date!()
    |> Timex.format!("{YYYY}-{0M}-{0D}")
  end

  defp migration_id(%{"id" => id}), do: id

  defp cms_format(value) do
    [%{"value": value}]
  end

  defp cms_format_body(value) do
    [%{"value": value, "format": "basic_html"}]
  end
end

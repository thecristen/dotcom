defmodule GoogleMaps do
  def signed_url(url, opts \\ []) do
    client_id = opts
    |> Keyword.get(:client_id, get_env(:client_id))

    signing_key = opts
    |> Keyword.get(:signing_key, get_env(:signing_key))

    do_signed_url(url, client_id, signing_key)
  end

  defp get_env(key, default \\ nil) do
    env = Application.get_env(:site, __MODULE__, [])
    Keyword.get(env, key, default)
  end

  defp do_signed_url(url, "", _), do: url |> append_api_key |> prepend_host
  defp do_signed_url(url, _, ""), do: url |> append_api_key |> prepend_host
  defp do_signed_url(url, client_id, signing_key) do
    "#{url}&client=#{client_id}"
    |> append_signature(signing_key)
    |> prepend_host
  end

  defp prepend_host(url) do
    "https://maps.googleapis.com#{url}"
  end

  defp append_api_key(url) do
    # Fallback to the existing API key for now. -ps
    "#{url}&key=#{Application.get_env(:site, Site.ViewHelpers)[:google_api_key]}"
  end

  defp append_signature(url, signing_key) do
    "#{url}&signature=#{signature(url, signing_key)}"
  end

  defp signature(url, key) do
    de64ed_key = Base.url_decode64!(key)

    binary_hash = :crypto.hmac(:sha, de64ed_key, url)

    Base.url_encode64(binary_hash)
  end
end

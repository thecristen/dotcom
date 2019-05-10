defmodule SiteWeb.EndpointTest do
  use SiteWeb.ConnCase, async: true
  alias SiteWeb.Endpoint

  test "init/2" do
    assert {:ok, config} = Endpoint.init(:test, [])

    assert Keyword.has_key?(config, :secret_key_base)
  end
end

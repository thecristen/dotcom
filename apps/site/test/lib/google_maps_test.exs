defmodule GoogleMapsTest do
  use ExUnit.Case, async: true

  # Needs to be 27 characters followed by =
  @signing_key "testtesttesttesttesttesttes="

  describe "signed_url/2" do
    test "appends the signature to the URL" do
      assert GoogleMaps.signed_url("/maps/api/staticmap/?arg", client_id: "test", signing_key: @signing_key) ==
        "https://maps.googleapis.com/maps/api/staticmap/?arg&client=test&signature=WsuBDD9RmzhtKESUiUKgzjgRGaU="
    end
  end
end

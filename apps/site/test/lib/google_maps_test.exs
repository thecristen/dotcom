defmodule GoogleMapsTest do
  use ExUnit.Case, async: true

  # Needs to be 27 characters followed by =
  @signing_key "testtesttesttesttesttesttes="

  # To verify signatures, you can use the online version at
  # https://developers.google.com/maps/documentation/static-maps/get-api-key#dig-sig-key

  describe "signed_url/2" do
    test "appends the signature to the URL" do
      assert GoogleMaps.signed_url("/maps/api/staticmap/?arg", client_id: "test", signing_key: @signing_key) ==
        "https://maps.googleapis.com/maps/api/staticmap/?arg&client=test&signature=WsuBDD9RmzhtKESUiUKgzjgRGaU="
    end

    test "appends the signature even without an existing query" do
      assert GoogleMaps.signed_url("/maps/api/staticmap/", client_id: "test", signing_key: @signing_key) ==
        "https://maps.googleapis.com/maps/api/staticmap/?client=test&signature=GqNL1_FyAXxPIy75Azb7Tohdg-k="
    end
  end
end

defmodule Content.CMS.HTTPClientTest do
  use ExUnit.Case

  @page_json "{\"nid\":[{\"value\":\"6\"}],\"uuid\":[{\"value\":\"a53215a8-b83a-4503-a349-7b54dbb07564\"}],\"vid\":[{\"value\":\"75\"}],\"langcode\":[{\"value\":\"en\"}],\"type\":[{\"target_id\":\"page\",\"target_type\":\"node_type\",\"target_uuid\":\"9e4b5efa-9303-469e-b5d6-20ef12fbe1d1\"}],\"title\":[{\"value\":\"Accessibility at the T\"}],\"uid\":[{\"target_id\":\"7\",\"target_type\":\"user\",\"target_uuid\":\"d403ed87-c9e8-46d0-963f-4f9719dc599b\",\"url\":\"\\/user\\/7\"}],\"status\":[{\"value\":\"1\"}],\"created\":[{\"value\":\"1482874857\"}],\"changed\":[{\"value\":\"1484163899\"}],\"promote\":[{\"value\":\"0\"}],\"sticky\":[{\"value\":\"0\"}],\"revision_timestamp\":[{\"value\":\"1484163899\"}],\"revision_uid\":[{\"target_id\":\"7\",\"target_type\":\"user\",\"target_uuid\":\"d403ed87-c9e8-46d0-963f-4f9719dc599b\",\"url\":\"\\/user\\/7\"}],\"revision_log\":[],\"revision_translation_affected\":[{\"value\":\"1\"}],\"default_langcode\":[{\"value\":\"1\"}],\"path\":[],\"body\":[{\"value\":\"<p>From accessible buses, trains, and stations, to a world-class paratransit service,&nbsp;the MBTA is dedicated to providing excellent service to customers of all abilities. We are striving to become the global benchmark for accessible public transportation\\u2014creating a system that is safe, dependable and inclusive, thereby expanding the transportation options available to all our customers, including those with disabilities.&nbsp; Select one of the links below to learn more about accessibility at the MBTA.<\\/p>\\r\\n\\r\\n<p>If you are a person with a disability and would like to submit a reasonable modification request,&nbsp;<a href=\\\"http:\\/\\/mbtastaging.mbta.com\\/customer_support\\/?id=6442454932\\\">click here<\\/a>&nbsp;to learn more.<\\/p>\\r\\n\\r\\n<p><strong><a href=\\\"http:\\/\\/mbtastaging.mbta.com\\/riding_the_t\\/accessible_services\\/default.asp?id=7108\\\">The Office for Transportation Access--THE RIDE<\\/a><\\/strong><br \\/>\\r\\nCustomers who are unable to use fixed-route services&nbsp; due to a disability may be eligible for MBTA paratransit service, THE RIDE.&nbsp; Click on the link above to learn more about this additional transportation option.<\\/p>\\r\\n\\r\\n<p><strong><a href=\\\"http:\\/\\/mbtastaging.mbta.com\\/riding_the_t\\/accessible_services\\/default.asp?id=16901\\\">Department of System-Wide Accessibility<\\/a><\\/strong><br \\/>\\r\\nEstablished in 2007, the T's Department of System-Wide Accessibility&nbsp;oversees programs and services for persons with disabilities and seniors.&nbsp; Today, the MBTA is more accessible than ever!&nbsp; Click on the link above to learn about the accessibility&nbsp;of our fixed-route services (buses, trains, and commuter boats), as well as the Department of System-Wide Accessibility.<\\/p>\\r\\n\\r\\n<p><a href=\\\"http:\\/\\/mbtastaging.mbta.com\\/riding_the_t\\/accessible_services\\/default.asp?id=26302\\\"><strong>Access Advisory Committee to the MBTA<\\/strong><\\/a><br \\/>\\r\\nThe Access Advisory Committee to the MBTA is a consumer body composed primarily of persons with disabilities. Customers, advocates and representatives of disability advocacy groups and agencies advise and make recommendations to the MBTA regarding accessible transportation for both its Fixed Route services (buses, subway and trains) and its Paratransit program, THE RIDE. Anyone is invited to participate. To learn more click on the link above.<\\/p>\\r\\n\",\"format\":\"full_html\",\"summary\":\"\"}],\"field_downloads\":[]}"

  setup_all _ do
    original_drupal_config = Application.get_env(:content, :drupal)
    bypass = Bypass.open
    Application.put_env(:content, :drupal,
      put_in(original_drupal_config[:root], "http://localhost:#{bypass.port}"))

    on_exit fn ->
      Application.put_env(:content, :drupal, original_drupal_config)
    end

    %{bypass: bypass}
  end

  describe "view/2" do
    test "Returns {:ok, parsed} if it all works", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "/page" == conn.request_path
        assert Plug.Conn.fetch_query_params(conn).params["_format"] == "json"
        Plug.Conn.resp(conn, 200, @page_json)
      end

      assert {:ok, %{}} = Content.CMS.HTTPClient.view("/page")
    end

    test "Returns error tuple if HTTP status code is not successful", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "/page" == conn.request_path
        assert Plug.Conn.fetch_query_params(conn).params["_format"] == "json"
        Plug.Conn.resp(conn, 404, "{\"message\":\"No page found\"}")
      end

      assert {:error, "HTTP status was 404"} = Content.CMS.HTTPClient.view("/page")
    end

    test "Returns error tuple if HTTP request fails", %{bypass: bypass} do
      Bypass.down bypass
      assert {:error, "Unknown error with HTTP request"} = Content.CMS.HTTPClient.view("/page")
      Bypass.up bypass
    end

    test "Returns error tuple if parsing failure", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "/page" == conn.request_path
        assert Plug.Conn.fetch_query_params(conn).params["_format"] == "json"
        Plug.Conn.resp(conn, 200, "{invalid")
      end

      assert {:error, "Could not parse JSON response"} = Content.CMS.HTTPClient.view("/page")
    end
  end
end

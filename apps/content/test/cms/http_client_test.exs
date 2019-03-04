defmodule Content.CMS.HTTPClientTest do
  use ExUnit.Case
  import Mock
  import Content.CMS.HTTPClient
  alias Content.ExternalRequest

  describe "preview/2" do
    test "uses alternate path with timeout options" do
      with_mock ExternalRequest, process: fn _method, _path, _body, _params -> {:ok, []} end do
        preview(6, 0)

        assert called(
                 ExternalRequest.process(
                   :get,
                   "/cms/revisions/6",
                   "",
                   params: [_format: "json", vid: 0],
                   timeout: 10_000,
                   recv_timeout: 10_000
                 )
               )
      end
    end
  end

  describe "view/2" do
    test "makes a get request with format: json params" do
      with_mock ExternalRequest, process: fn _method, _path, _body, _params -> {:ok, []} end do
        view("/path", [])
        assert called(ExternalRequest.process(:get, "/path", "", params: [{"_format", "json"}]))
      end
    end

    test "accepts additional params" do
      with_mock ExternalRequest, process: fn _method, _path, _body, _params -> {:ok, []} end do
        view("/path", foo: "bar")

        assert called(
                 ExternalRequest.process(
                   :get,
                   "/path",
                   "",
                   params: [{"_format", "json"}, {"foo", "bar"}]
                 )
               )
      end
    end

    test "accepts atoms as param values" do
      with_mock ExternalRequest, process: fn _, _, _, _ -> {:ok, []} end do
        view("/path", foo: :bar)

        assert called(
                 ExternalRequest.process(
                   :get,
                   "/path",
                   "",
                   params: [{"_format", "json"}, {"foo", "bar"}]
                 )
               )
      end
    end

    test "illegal param values are dropped" do
      with_mock ExternalRequest, process: fn _method, _path, _body, _params -> {:ok, []} end do
        view("/path", %{"foo" => ["bar", "baz"]})

        assert called(
                 ExternalRequest.process(
                   :get,
                   "/path",
                   "",
                   params: [{"_format", "json"}]
                 )
               )

        view("/path", %{"foo" => %{"bar" => "baz"}})

        assert called(
                 ExternalRequest.process(
                   :get,
                   "/path",
                   "",
                   params: [{"_format", "json"}]
                 )
               )
      end
    end
  end

  describe "post/2" do
    test "makes a post request" do
      with_mock ExternalRequest, process: fn _method, _path, _body -> {:ok, []} end do
        post("/path", "body")
        assert called(ExternalRequest.process(:post, "/path", "body"))
      end
    end
  end

  describe "update/2" do
    test "makes a patch request" do
      with_mock ExternalRequest, process: fn _method, _path, _body -> {:ok, []} end do
        update("/path", "body")
        assert called(ExternalRequest.process(:patch, "/path", "body"))
      end
    end
  end
end

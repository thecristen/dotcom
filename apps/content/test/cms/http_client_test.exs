defmodule Content.CMS.HTTPClientTest do
  use ExUnit.Case
  import Mock
  import Content.CMS.HTTPClient
  alias Content.ExternalRequest

  describe "view/2" do
    test "makes a get request with format: json params" do
      with_mock ExternalRequest, [process: fn(_method, _path, _body, _params) -> {:ok, []} end] do
        view("/path")
        assert called ExternalRequest.process(:get, "/path", "", [_format: "json"])
      end
    end

    test "accepts additional params" do
      with_mock ExternalRequest, [process: fn(_method, _path, _body, _params) -> {:ok, []} end] do
        view("/path", [foo: "bar"])
        assert called ExternalRequest.process(:get, "/path", "", [foo: "bar", _format: "json"])
      end
    end
  end

  describe "post/2" do
    test "makes a post request" do
      with_mock ExternalRequest, [process: fn(_method, _path, _body) -> {:ok, []} end] do
        post("/path", "body")
        assert called ExternalRequest.process(:post, "/path", "body")
      end
    end
  end

  describe "update/2" do
    test "makes a patch request" do
      with_mock ExternalRequest, [process: fn(_method, _path, _body) -> {:ok, []} end] do
        update("/path", "body")
        assert called ExternalRequest.process(:patch, "/path", "body")
      end
    end
  end
end

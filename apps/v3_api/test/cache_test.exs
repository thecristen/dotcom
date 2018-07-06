defmodule V3Api.CacheTest do
  use ExUnit.Case, async: true
  import V3Api.Cache
  alias HTTPoison.Response

  @name __MODULE__
  @url "/url"
  @params []
  @last_modified "Fri, 06 Jul 2018 14:03:30 GMT"
  @response %Response{
    status_code: 200,
    body: "body",
    headers: [
      {"Server", "Fake Server"},
      {"Last-Modified", @last_modified}
    ]
  }

  setup do
    {:ok, _pid} = start_link(name: @name)
    :ok
  end

  describe "cache_response/3" do
    test "304 response: returns a previously cached response" do
      _ = cache_response(@name, @url, @params, @response)
      not_modified = %{@response | status_code: 304}
      assert {:ok, @response} == cache_response(@name, @url, @params, not_modified)
    end

    test "200 response: returns the same response" do
      assert {:ok, @response} == cache_response(@name, @url, @params, @response)
    end

    test "400 response: returns the same response" do
      response = %{@response | status_code: 400}
      assert {:ok, response} == cache_response(@name, @url, @params, response)
    end

    test "404 response: returns the same response" do
      response = %{@response | status_code: 404}
      assert {:ok, response} == cache_response(@name, @url, @params, response)
    end

    test "500 response: returns the same response if not cached" do
      response = %{@response | status_code: 500}
      assert {:ok, response} == cache_response(@name, @url, @params, response)
    end

    test "500 response: returns a cached response if available" do
      _ = cache_response(@name, @url, @params, @response)
      response = %{@response | status_code: 500}
      assert {:ok, @response} == cache_response(@name, @url, @params, response)
    end
  end

  describe "cache_headers/2" do
    test "returns an empty list if there's nothing cached" do
      assert cache_headers(@name, @url, @params) == []
    end

    test "once a response is cached, returns the last-modified header" do
      _ = cache_response(@name, @url, @params, @response)
      assert cache_headers(@name, @url, @params) == [{"if-modified-since", @last_modified}]
    end
  end
end

defmodule RepoCache do
  @moduledoc """

  Helps repositories cache their results easily.

  ## Usage

  defmodule Repo do
    use RepoCache

    def method(opts) do
      opts
      |> cache(fn opts ->
        # long process returning the data to cache
      end)
    end
  end

  ## Options

  Both `use` and calls to `cache` take a `ttl` parameter, which is a number
  of milliseconds to cache the value.

  """
  defmacro __using__(opts \\ []) do
    ttl = opts
    |> Keyword.get(:ttl, :timer.seconds(1))

    quote do
      require RepoCache
      import RepoCache

      @default_cache_params [{:ttl, unquote(ttl)}]
    end
  end

  defmacro cache(func_param, func, cache_opts \\ []) do
    quote do
      do_cache(
        unquote(func_param),
        __ENV__,
        unquote(func),
        Keyword.merge(@default_cache_params, unquote(cache_opts)))
    end
  end

  def do_cache(func_param, %{context_modules: [module|_],
                                   function: {name, _}}, func, cache_opts) do
    ConCache.get_or_store(:repo_cache_cache, {module, name, func_param}, fn ->
      value = func.(func_param)

      # don't cache if we don't get values back: 1 is the smallest amount of
      # time we can cache.
      ttl = case value do
              [] -> 1
              nil -> 1
              _ -> cache_opts[:ttl]
            end

      %ConCache.Item{value: value, ttl: ttl}
    end)
  end
end

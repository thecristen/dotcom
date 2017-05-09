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
  @cache_name :repo_cache_cache

  defmacro __using__(opts \\ []) do
    ttl = opts
    |> Keyword.get(:ttl, :timer.seconds(1))

    quote do
      require RepoCache
      import RepoCache

      defdelegate clear_cache(), to: RepoCache

      @default_cache_params [{:ttl, unquote(ttl)}, {:timeout, nil}]
    end
  end

  def clear_cache do
    @cache_name
    |> ConCache.ets
    |> :ets.tab2list
    |> Enum.reduce(:ok, fn {key, _}, _ ->
      ConCache.delete(@cache_name, key)
      :ok
    end)
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
    key = {module, name, func_param}
    timeout = cache_opts[:timeout]
    ConCache.isolated @cache_name, key, timeout, fn ->
      case ConCache.get(@cache_name, key) do
        nil ->
          maybe_set_value(func.(func_param), key, cache_opts[:ttl])
        value ->
          value
      end
    end
  end

  defp maybe_set_value({:error, _} = error, _, _) do
    error
  end
  defp maybe_set_value(value, key, ttl) do
    item = %ConCache.Item{value: value, ttl: ttl}
    ConCache.dirty_put(@cache_name, key, item)
    value
  end
end

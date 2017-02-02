defmodule News.Repo.Ets do
  @behaviour News.Repo
  use GenServer

  @ets_table __MODULE__

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def update(files) when is_list(files) do
    :ok = GenServer.call(__MODULE__, {:update, files})
  end

  def all_ids do
    :ets.select(@ets_table, [{{:"$1", :_}, [], [:"$1"]}])
  end

  def get(id) do
    case :ets.lookup(@ets_table, id) do
      [{^id, contents}] -> {:ok, contents}
      other -> {:error, other}
    end
  end

  # Server callbacks
  def init(nil) do
    @ets_table = :ets.new(@ets_table, [:named_table, read_concurrency: true])
    {:ok, nil}
  end

  def handle_call({:update, files}, _from, state) do
    :ets.insert(@ets_table, files)
    {:reply, :ok, state}
  end
end

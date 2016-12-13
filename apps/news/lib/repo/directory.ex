defmodule News.Repo.Directory.PostDirectory do
  def post_dir do
    config_dir = Application.fetch_env!(:news, :post_dir)
    case config_dir do
      <<"/", _::binary>> -> config_dir
      _ -> Application.app_dir(:news, config_dir)
    end
  end
end

defmodule News.Repo.Directory do
  @behaviour News.Repo
  import News.Repo.Directory.PostDirectory

  @post_filenames post_dir()
  |> File.ls!

  def all_ids do
    @post_filenames
  end

  def get(id) do
    post_dir()
    |> Path.join(id)
    |> File.read
  end
end

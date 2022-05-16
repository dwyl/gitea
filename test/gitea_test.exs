defmodule GiteaTest do
  use ExUnit.Case
  alias Gitea.Helpers, as: GH
  doctest Gitea

  test "clone repository error" do
    gitea_server_url = Application.get_env(:gitea, :gitea_server_url)

    git_url = GH.remote_git_url(gitea_server_url, "non", "non")

    assert {:error, _err} = Gitea.clone(git_url)
  end

  test "clone existing repository" do
    gitea_server_url = Application.get_env(:gitea, :gitea_server_url)
    git_url = GH.remote_git_url(gitea_server_url, "gitea-test", "public-repo")

    assert {:ok, path} = Gitea.clone(git_url)
    # clean test by removing the created repository
    File.rm_rf(path)
  end
end

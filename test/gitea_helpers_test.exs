defmodule Gitea.HelpersTest do
  use ExUnit.Case, async: true
  doctest Gitea.Helpers

  test "Gitea.Helpers.api_base_url/0 returns the API URL for the gitea Server" do
    assert Gitea.Helpers.api_base_url() == "https://gitea-server.fly.dev/api/v1/"
  end

  test "temp_dir/1 returns cwd if no dir supplied" do
    assert Gitea.Helpers.temp_dir(nil) == File.cwd!()
  end

  test "temp_dir/1 returns dir when dir exists" do
    assert Gitea.Helpers.temp_dir("test-repo") == "test-repo"
  end

  test "make_url/2 (without port) returns a valid GitHub Base URL" do
    url = "github.com"
    git_url = Gitea.Helpers.make_url(url)
    assert git_url == "git@github.com:"
  end

  test "make_url/2 returns a valid gitea (Fly.io) Base URL" do
    git_url = Gitea.Helpers.make_url("gitea-server.fly.dev")
    assert git_url == "git@gitea-server.fly.dev:"
  end

  test "remote_url/3 returns a valid gitea (Fly.io) remote URL" do
    git_url = Gitea.Helpers.make_url("gitea-server.fly.dev")
    remote_url = Gitea.Helpers.remote_url(git_url, "nelsonic", "public-repo")
    assert remote_url == "git@gitea-server.fly.dev:nelsonic/public-repo.git"
  end
end

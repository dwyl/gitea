defmodule GiteaGitMockTest do
  use ExUnit.Case, async: true
  # This file is just for exercising the mock functions
  # Ignore it

  # can you think of a better way of testing/simulating this error condition?
  test "Gitea.GitMock.clone {:error, %Git.Error{message}}" do
    repo = "error"
    org = "myorg"
    url = Gitea.Helpers.remote_url_ssh(org, repo)
    {:error, %Git.Error{message: response_message}} = Gitea.GitMock.clone(url)
    expected = "git clone error (mock)"
    assert expected == response_message
  end

  test "Gitea.GitMock.clone returns {:ok, %Git.Repository{path: local_path}}" do
    expected = Gitea.Helpers.local_repo_path("test-org", "test-repo")
    {:ok, %Git.Repository{path: local_path}} = Gitea.GitMock.clone("any-url")
    assert expected == local_path
  end

  test "Gitea.GitMock.clone with list recurses using the first param as url" do
    expected = Gitea.Helpers.local_repo_path("test-org", "test-repo")

    {:ok, %Git.Repository{path: local_path}} =
      Gitea.GitMock.clone(["any-url", "/path/to/local/repo"])

    assert expected == local_path
  end

  test "Gitea.GitMock.push mocks pushing to a remote repo" do
    org_name = "test-org"
    repo_name = "test-repo"
    expected = "To ssh://gitea-server.fly.dev:10022/myorg/#{repo_name}.git\n"
    git_repo = %Git.Repository{path: Gitea.Helpers.local_repo_path(org_name, repo_name)}
    {:ok, msg} = Gitea.GitMock.push(git_repo, ["any"])
    assert expected == msg
  end
end

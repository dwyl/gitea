defmodule Gitea.Git.Mock do
  @moduledoc """
  Mock Git clone command as it is easier to use this module
  with CI than imlementing ssh on Github CI
  """
  alias Gitea.Helpers, as: GH

  @doc """
  `clone/1` (mock) returns either {:ok, local_path} or {:error, _reason}
  so that no remote cloning occurs. This is needed for CI and
  is used in downstream tests to speed up suite execution.

    ## Examples
    iex> Gitea.Git.Mock.clone("ssh://gitea-server.fly.dev:myorg/public-repo.git")
    {:ok, "/myorg/public-repo"}

    iex> GitMock.clone("git@error:error/error.git")
    {:error, "couldn't clone repository"}
  """
  @spec clone(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def clone(_git_repo_url)
  def clone("git@error:error/error.git"), do: {:error, "couldn't clone repository"}

  def clone(git_repo_url) do
    {org_name, repo_name} = GH.get_org_repo_names_from_git_url(git_repo_url)
    local_path = GH.local_repo_path(org_name, repo_name)
    {:ok, local_path}
  end
end

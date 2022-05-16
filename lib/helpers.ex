defmodule Gitea.Helpers do
  @moduledoc """
  Helper functions
  """

  @doc """
  Returns a git url based on a url, org name and repo name

  ## Examples
    iex> Gitea.Helpers.remote_git_url("gitea-server.fly.dev", "myorg", "myrepo")
    "git@gitea-server.fly.dev:myorg/myrepo.git"
  """
  @spec remote_git_url(String.t(), String.t(), String.t()) :: String.t()
  def remote_git_url(url, org, repo), do: "git@#{url}:#{org}/#{repo}.git"

  @doc """
  returns {org, repo} from git url

  ## Examples
    iex> Gitea.Helpers.get_org_repo_names_from_git_url("git@gitea-server.fly.dev:myorg/myrepo.git")
    {"myorg", "myrepo"}
  """
  @spec get_org_repo_names_from_git_url(String.t()) :: {String.t(), String.t()}
  def get_org_repo_names_from_git_url(url) do
    url
    |> String.split(":")
    |> List.last()
    |> Path.rootname()
    |> Path.split()
    |> List.to_tuple()
  end

  @doc """
  Retuns local path for cloned repository:
  temp_dir/org_name/repo_name
  """
  def local_repo_path(org, repo) do
    # directory where to save clone repos, default to "."
    git_root_path = Application.get_env(:gitea, :git_temp_dir_path, ".")

    [git_root_path, org, repo]
    |> Path.join()
    |> Path.expand()
  end
end

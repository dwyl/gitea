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
end

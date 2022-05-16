defmodule Gitea do
  @moduledoc """
  Documentation for `Gitea`.
  """

  alias Gitea.Helpers, as: GH
  require Logger

  # return Git module based on environment
  defp inject_git() do
    Git
  end

  @doc """
  `clone/1` clones a remote git repository based on `git_repo_url`
  returns the {:ok, path} where path is the _local_ copy of the repository,
  or {:error, _reason}
  """
  @spec clone(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def clone(git_repo_url) do
    {org_name, repo_name} = GH.get_org_repo_names_from_git_url(git_repo_url)
    local_path = GH.local_repo_path(org_name, repo_name)

    case inject_git().clone([git_repo_url, local_path]) do
      {:ok, %Git.Repository{path: path}} ->
        {:ok, path}

      {:error, err} ->
        Logger.debug(err)
        {:error, "couldn't clone repository"}
    end
  end
end

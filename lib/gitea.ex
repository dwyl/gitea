defmodule Gitea do
  @moduledoc """
  Documentation for `Gitea`.

  In your application define the following configuration
  config :gitea, git_temp_dir_path: "/",
               , 
  """

  @gitea :gitea

  # return Git module based on environment
  defp inject_git() do
    Git
  end

  @doc """
  `clone/1` clones a remote git repository based on `git_repo_url`
  returns the path of the _local_ copy of the repository.
  """
  @spec clone(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def clone(git_repo_url) do
    {org_name, repo_name} = get_org_repo_names_from_url(git_repo_url)
    local_path = local_repo_path(org_name, repo_name)

    case inject_git().clone([git_repo_url, local_path]) do
      {:ok, %Git.Repository{path: path}} ->
        {:ok, path}

      {:error, _err} ->
        {:error, "couldn't clone repository"}
    end
  end

  # returns {org, repo} from git url
  @spec get_org_repo_names_from_url(String.t()) :: {String.t(), String.t()}
  defp get_org_repo_names_from_url(url) do
    url
    |> Path.split()
    |> Enum.take(-2)
    |> List.to_tuple()
  end

  # return path for repo
  defp local_repo_path(org, repo) do
    git_root_path = Application.get_env(@gitea, :git_temp_dir_path, ".")
    Path.join(git_root_path, [org, repo])
  end
end

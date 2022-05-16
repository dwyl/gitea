defmodule Gitea do
  @moduledoc """
  Documentation for `Gitea`.

  In your application define the following configuration
  config :gitea, git_temp_dir_path: "/",
               , 
  """

  import Gitea.Helpers
  require Logger

  @mock Application.compile_env(:gitea, :mock)
  Logger.debug("Gogs > config :gitea, mock: #{to_string(@mock)}")
  @git (@mock && Gitea.GitMock) || Git

  @doc """
  `inject_git/0` injects a `Git` TestDouble in Tests & CI
  so we don't have duplicate mocks in the downstream app.
  """
  def inject_git, do: @git

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

  @doc """
  `remote_read_file/4` reads a file from the remote repo.
  Accepts 4 arguments: `org_name`, `repo_name`, `file_name` and `branch_name`.
  The 4<sup>th</sup> argument is *optional* and defaults to `"master"` 
  (the default branch for a repo hosted on `Gogs`).
  Makes a `GET` request to the remote `Gogs` instance as defined 
  by the environment variable `GITEA_SERVER_URL`.
  Returns `{:ok, %HTTPoison.Response{ body: response_body}}`
  Uses REST API Endpoint:
  ```sh
  GET /repos/:username/:reponame/raw/:branchname/:path
  ```
  """
  @spec remote_read_raw(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map} | {:error, any}
  def remote_read_raw(org_name, repo_name, file_name, branch_name \\ "master") do
    url = api_base_url() <> "repos/#{org_name}/#{repo_name}/raw/#{branch_name}/#{file_name}"
    Logger.debug("Gitea.remote_read_raw: #{url}")
    Gitea.Http.get_raw(url)
  end

  @doc """
  `remote_render_markdown_html/4` uses `Gog` built-in Markdown processor 
  to render a Markdown Doc e.g. the `README.md` so you can easily use the HTML.
  Accepts 4 arguments: `org_name`, `repo_name`, `file_name` and `branch_name`.
  The 4<sup>th</sup> argument is *optional* and defaults to `"master"` 
  (the default branch for a repo hosted on `Gogs`).
  Makes a `GET` request to the remote `Gogs` instance as defined 
  by the environment variable `GOGS_URL`.
  Returns `{:ok, %HTTPoison.Response{ body: response_body}}`
  Uses REST API Endpoint:
  ```sh
  POST /markdown/raw
  ```
  Ref: https://github.com/dwyl/gogs/issues/23
  """
  @spec remote_render_markdown_html(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map} | {:error, any}
  def remote_render_markdown_html(org_name, repo_name, file_name, branch_name \\ "master") do
    # First retrieve the Raw Markdown Text we want to render:
    {:ok, %HTTPoison.Response{body: raw_markdown}} =
      Gitea.remote_read_raw(org_name, repo_name, file_name, branch_name)
    
    Logger.debug("raw_markdown: #{raw_markdown}")

    url = api_base_url() <> "markdown/raw"
    Logger.info("remote_render_markdown_html/4 #{url}")
    # temp_context = "https://github.com/gogs/gogs"
    # Ask Gogs to redner the Raw Markdown to HTML:
    Gitea.Http.post_raw_html(url, raw_markdown)
    # I agree, this is clunky ... We wont use it for latency-sensitive apps.
    # But it could be useful for a quick/easy Static Site / Blog App. 💭
  end

  # returns {org, repo} from git url
  @spec get_org_repo_names_from_url(String.t()) :: {String.t(), String.t()}
  defp get_org_repo_names_from_url(url) do
    url
    |> Path.split()
    |> Enum.take(-2)
    |> List.to_tuple()
  end

  # # return path for repo
  # defp local_repo_path(org, repo) do
  #   git_root_path = Application.get_env(@gitea, :git_temp_dir_path, ".")
  #   Path.join(git_root_path, [org, repo])
  # end
end

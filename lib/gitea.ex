defmodule Gitea do
  @moduledoc """
  Documentation for the main `Gitea` functions.
  This package is an `Elixir` interface to our `Gitea` Server.
  It contains all functions we need to create repositories,
  clone, add data to files, commit, push and diff.
  Some of these functions use `Git` and others use the `REST API`.
  We would _obviously_ prefer if everything was one or the other,
  but sadly, some things cannot be done via `Git` or `REST`
  so we have adopted a "hybrid" approach.

  If anything is unclear, please open an issue:
  [github.com/dwyl/**gitea/issues**](https://github.com/dwyl/gitea/issues)
  """
  import Gitea.Helpers
  require Logger

  @mock Application.compile_env(:gitea, :mock)
  Logger.debug("Gitea > config :gitea, mock: #{to_string(@mock)}")
  @git (@mock && Gitea.GitMock) || Git

  @doc """
  `inject_git/0` injects a `Git` TestDouble in Tests & CI
  so we don't have duplicate mocks in the downstream app.
  """
  def inject_git, do: @git

  @doc """
  `remote_repo_create/3` accepts 3 arguments: `org_name`, `repo_name` & `private`.
  It creates a repo on the remote `Gitea` instance as defined
  by the environment variable `GITEA_URL`.
  For convenience it assumes that you only have _one_ `Gitea` instance.
  If you have more or different requirements, please share!
  """
  @spec remote_repo_create(String.t(), String.t(), boolean) ::
          {:ok, :repo_created} | {:error, Gitea.Error}
  def remote_repo_create(org_name, repo_name, private \\ false) do
    url = api_base_url() <> "org/#{org_name}/repos"
    Logger.info("remote_repo_create api endpoint: #{url}")

    params = %{
      auto_init: true,
      name: repo_name,
      private: private,
      description: repo_name
    }

    case Gitea.Http.post(url, params) do
      {:ok, _status_code} ->
        {:ok, :repo_created}

      {:error, _reason} ->
        {:error,
         %Gitea.Error{
           message: "Can't create remote repository"
         }}
    end
  end

  @doc """
  Create an organisation on Gitea.
  The second argument opts is a keyword list value
  and define the description, full_name and visibility
  """
  @spec remote_org_create(%{
          required(:username) => String.t(),
          optional(:description) => String.t(),
          optional(:full_name) => String.t(),
          optional(:visibility) => String.t()
        }) :: {:ok, map} | {:error, any}
  def remote_org_create(params) do
    url = api_base_url() <> "orgs"

    Gitea.Http.post(url, params)
  end

  @doc """
  Delete an organisation on Gitea.
  """
  @spec remote_org_delete(String.t()) :: {:ok, map} | {:error, any}
  def remote_org_delete(org_name) do
    url = api_base_url() <> "orgs/#{org_name}"

    Gitea.Http.delete(url)
  end

  @doc """
  `remote_repo_delete/2` accepts two arguments: `org_name` and `repo_name`.
  It deletes the repo on the remote `Gitea` instance as defined
  by the environment variable `GITEA_URL`.
  """
  @spec remote_repo_delete(String.t(), String.t()) :: {:ok, map} | {:error, any}
  def remote_repo_delete(org_name, repo_name) do
    url = api_base_url() <> "repos/#{org_name}/#{repo_name}"
    Logger.info("remote_repo_delete: #{url}")
    Gitea.Http.delete(url)
  end

  @doc """
  `remote_read_file/4` reads a file from the remote repo.
  Accepts 4 arguments: `org_name`, `repo_name`, `file_name` and `branch_name`.
  The 4<sup>th</sup> argument is *optional* and defaults to `"master"`
  (the default branch for a repo hosted on `Gitea`).
  Makes a `GET` request to the remote `Gitea` instance as defined
  by the environment variable `GITEA_URL`.
  Returns `{:ok, %HTTPoison.Response{ body: response_body}}`
  Uses REST API Endpoint:
  ```sh
  GET /repos/:username/:reponame/raw/:branchname/:path
  ```
  Ref: https://github.com/gitea/docs-api/blob/master/Repositories/Contents.md#get-contents
  """
  @spec remote_read_raw(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map} | {:error, any}
  def remote_read_raw(org_name, repo_name, file_name, branch_name \\ "master") do
    url = api_base_url() <> "repos/#{org_name}/#{repo_name}/raw/#{branch_name}/#{file_name}"
    Logger.debug("Gitea.remote_read_raw: #{url}")
    Gitea.Http.get_raw(url)
  end

  @doc """
  `remote_render_markdown_html/4` uses `Gitea` built-in Markdown processor
  to render a Markdown Doc e.g. the `README.md` so you can easily use the HTML.
  Accepts 4 arguments: `org_name`, `repo_name`, `file_name` and `branch_name`.
  The 4<sup>th</sup> argument is *optional* and defaults to `"master"`
  (the default branch for a repo hosted on `Gitea`).
  Makes a `GET` request to the remote `Gitea` instance as defined
  by the environment variable `GITEA_URL`.
  Returns `{:ok, %HTTPoison.Response{ body: response_body}}`
  Uses REST API Endpoint:
  ```sh
  POST /markdown/raw
  ```
  Ref: https://github.com/dwyl/gitea/issues/23
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
    # temp_context = "https://github.com/gitea/gitea"
    # Ask Gitea to redner the Raw Markdown to HTML:
    Gitea.Http.post_raw_html(url, raw_markdown)
    # I agree, this is clunky ... We wont use it for latency-sensitive apps.
    # But it could be useful for a quick/easy Static Site / Blog App. 💭
  end

  @doc """
  `clone/1` clones a remote git repository based on `git_repo_url`
  returns the path of the _local_ copy of the repository.
  """
  @spec clone(String.t()) :: {:ok, String.t()} | {:error, Gitea.Error}
  def clone(git_repo_url) do
    org_name = get_org_name_from_url(git_repo_url)
    repo_name = get_repo_name_from_url(git_repo_url)
    local_path = local_repo_path(org_name, repo_name)
    Logger.info("git clone #{git_repo_url} #{local_path}")

    case inject_git().clone([git_repo_url, local_path]) do
      {:ok, %Git.Repository{path: path}} ->
        # Logger.info("Cloned repo: #{git_repo_url} to: #{path}")
        {:ok, path}

      {:error, git_err} ->
        Logger.error("Gitea.clone/1 tried to clone #{git_repo_url}, got: #{git_err.message}")

        {:error,
         %Gitea.Error{
           message: "git clone #{git_repo_url} failed: #{git_err.message}",
           reason: :clone_error
         }}
    end
  end

  @doc """
  `clone/2` clones a remote git repository based on `git_repo_url`.
  The second argument is a list of string representing where to clone the
  repository to.
  The functin returns either {:ok, path} or {:error, reason}
  """
  @spec clone(String.t(), list(String.t())) :: {:ok, String.t()} | {:error, Gitea.Error}
  def clone(git_repo_url, path) do
    local_path = create_local_path(path)
    Logger.info("git clone #{git_repo_url} #{local_path}")

    case inject_git().clone([git_repo_url, local_path]) do
      {:ok, %Git.Repository{path: path}} ->
        {:ok, path}

      {:error, git_err} ->
        {:error,
         %Gitea.Error{
           message: "git clone #{git_repo_url} failed: #{git_err.message}",
           reason: :clone_error
         }}
    end
  end

  @doc """
  `local_branch_create/3` creates a branch with the specified name
  or defaults to "draft", and switch to this branch.
  """
  @spec local_branch_create(String.t(), String.t(), String.t()) :: {:ok, map} | {:error, any}
  def local_branch_create(org_name, repo_name, branch_name \\ "draft") do
    case Git.checkout(local_git_repo(org_name, repo_name), ["-b", branch_name]) do
      {:ok, res} ->
        {:ok, res}

      {:error, git_err} ->
        Logger.error(
          "Git.checkout error: #{git_err.message}, #{repo_name} (should not thow error)"
        )

        {:error, git_err.message}
    end
  end

  @doc """
  `create_branch/3` creates a branch.
  """
  @spec create_branch(String.t(), String.t(), String.t()) :: {:ok, any} | {:error, Gitea.Error}
  def create_branch(org_name, repo_name, branch_name) do
    case Git.branch(local_git_repo(org_name, repo_name), [branch_name]) do
      {:ok, res} ->
        {:ok, res}

      {:error, _git_err} ->
        err = %Gitea.Error{message: "Couldn't create #{branch_name} branch"}
        {:error, err}
    end
  end

  @spec switch_branch(String.t(), String.t(), String.t()) :: {:ok, any} | {:error, Gitea.Error}
  def switch_branch(org_name, repo_name, branch_name) do
    case Git.checkout(local_git_repo(org_name, repo_name), [branch_name]) do
      {:ok, res} ->
        {:ok, res}

      {:error, _git_err} ->
        err = %Gitea.Error{message: "Couldn't switch to #{branch_name} branch"}
        {:error, err}
    end
  end

  @doc """
  `local_file_read/3` reads the raw text from the `file_name`,
  params: `org_name`, `repo_name` & `file_name`
  """
  @spec local_file_read(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def local_file_read(org_name, repo_name, file_name) do
    file_path = Path.join([local_repo_path(org_name, repo_name), file_name])
    File.read(file_path)
  end

  @doc """
  `local_file_write_text/3` writes the desired `text`,
  to the `file_name` in the `repo_name`.
  Touches the file in case it doesn't already exist.
  """
  @spec local_file_write_text(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, Gitea.Error}
  def local_file_write_text(org_name, repo_name, file_name, text) do
    file_path =
      local_repo_path(org_name, repo_name)
      |> Path.join(file_name)

    Logger.info("attempting to write to #{file_path}")

    case File.write(file_path, text) do
      :ok ->
        {:ok, file_path}

      {:error, _reason} ->
        {:error,
         %Gitea.Error{message: "Couldn't write file in repository", reason: :write_file_error}}
    end
  end

  @doc """
  `commit/3` commits the latest changes on the local branch.
  Accepts the `repo_name` and a `Map` of `params`:
  `params.message`: the commit message you want in the log
  `params.full_name`: the name of the person making the commit
  `params.email`: email address of the person committing.
  """
  @spec commit(String.t(), String.t(), %{
          message: String.t(),
          full_name: String.t(),
          email: String.t()
        }) :: {:ok, any} | {:error, Gitea.Error}
  def commit(org_name, repo_name, params) do
    repo = local_git_repo(org_name, repo_name)

    with {:ok, _output} <- inject_git().add(repo, ["."]),
         {:ok, commit_output} <-
           inject_git().commit(repo, [
             "-m",
             params.message,
             ~s(--author="#{params.full_name} <#{params.email}>")
           ]) do
      {:ok, commit_output}
    else
      {:error, _err} ->
        {:error, %Gitea.Error{message: "Commit error", reason: :commit_error}}
    end
  end

  @doc """
  `push/2` pushes the `org_name/repo_name` (current active branch)
  to the remote repository URL. Mocked during test/CI.
  """
  @spec push(String.t(), String.t()) :: {:ok, any} | {:error, any}
  def push(org_name, repo_name) do
    # Get the current git branch:
    git_repo = local_git_repo(org_name, repo_name)
    {:ok, branch} = Git.branch(git_repo, ~w(--show-current))
    # Remove trailing whitespace as Git chokes on it:
    branch = String.trim(branch)
    # Push the current branch:
    inject_git().push(git_repo, ["-u", "origin", branch])
  end
end

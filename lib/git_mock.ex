defmodule Gitea.GitMock do
  @moduledoc """
  Mock functions to simulate Git commands.
  Sadly, this is necessary until we figure out how to get write-access
  on GitHub CI. This module is exported for testing convenience/speed
  in downstream/dependent apps.
  """
  require Logger

  @doc """
  `clone/1` (mock) returns the path of the existing `test-repo`
  so that no remote cloning occurs. This is needed for CI and
  is used in downstream tests to speed up suite execution.

    ## Examples
    iex> GitMock.clone("ssh://gitea-server.fly.dev:10022/myorg/public-repo.git")
    {:ok, %Git.Repository{path: "/path/to/public-repo"}}

    iex> GitMock.clone("any-url-containing-the-word-error-to-trigger-failure")
    {:error, %Git.Error{message: "git clone error (mock)"}}
  """
  @spec clone(String.t() | list(String.t())) :: {:ok, Git.Repository.t()} | {:error, Git.Error}
  def clone(url) do
    case Useful.typeof(url) do
      # e.g: ["ssh://git@Gitea.dev/myorg/error-test.git", "tmp/test-repo"]
      # recurse using just the url (String) portion of the list:
      "list" ->
        url |> List.first() |> clone()

      "binary" ->
        Logger.info("Gitea.GitMock.clone #{url}")

        if String.contains?(url, "error") do
          {:error, %Git.Error{message: "git clone error (mock)"}}
        else
          # copy the contents of /test-repo into /tmp/test-repo when mock:true
          path = Gitea.Helpers.local_repo_path("test-org", "test-repo")
          submodule = Path.join([File.cwd!(), "test-repo"]) |> Path.expand()
          File.mkdir_p(path)
          File.cp_r(Path.join([submodule, ".git"]), path)
          File.copy(Path.join([submodule, "README.md"]), path)
          {:ok, %Git.Repository{path: path}}
        end
    end
  end

  @doc """
  `push/1` (mock) pushes the latest commits on the current branch
  to the Gitea remote repository.

    ## Examples
    iex> GitMock.push("my-repo")
    {:ok, "To ssh://gitea-server.fly.dev:10022/myorg/my-repo.git\n"}
  """
  @spec push(Git.Repository.t(), [any]) :: {:ok, any}
  def push(%Git.Repository{path: repo_path}, _args) do
    Logger.info("Gitea.GitMock.push #{repo_path}")
    repo_name = Gitea.Helpers.get_repo_name_from_url(repo_path <> ".git")
    {:ok, "To ssh://gitea-server.fly.dev:10022/myorg/#{repo_name}.git\n"}
  end

  @doc """
  `commit/2` (mock) simulate a commit and always returns {:ok, commit_info}

    ## Examples
    iex> GitMock.commit("my-repo", ["any", "args"])
    {:ok, "[master dc5b0d4] test msg\n Author: Al Ex <c@t.co>\n 1 file changed, 1 insertion(+)\n"}
  """
  @spec commit(Git.Repository.t(), [any]) :: {:ok, any}
  def commit(repo, _args) do
    if String.contains?(repo.path, "error") do
      {:error, %Git.Error{message: "git commit error (mock)"}}
    else
      {:ok,
       "[master dc5b0d4] test msg\n Author: Al Ex <c@t.co>\n 1 file changed, 1 insertion(+)\n"}
    end
  end

  @doc """
  `add/2` (mock) simulate a commit and always returns {:ok, any}

    ## Examples
    iex> GitMock.add("my-repo", ["."])
    {:ok, "totes always works"}
  """
  @spec add(Git.Repository.t(), [any]) :: {:ok, any}
  def add(_repo_path, _args) do
    {:ok, "totes always works"}
  end
end

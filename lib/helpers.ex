defmodule Gitea.Helpers do
  @moduledoc """
  Helper functions that can be unit tested independently of the main functions.
  If you spot any way to make these better, please share:
  https://github.com/dwyl/gitea/issues
  """
  require Logger
  # @env_required ~w/GITEA_URL GITEA_ACCESS_TOKEN/
  @mock Application.compile_env(:gitea, :mock)

  defp git_dir(), do: Envar.get("GIT_TEMP_DIR_PATH", File.cwd!())

  @doc """
  `api_base_url/0` returns the `Gitea` Server REST API url for API requests.

  ## Examples
    iex> Gitea.Helpers.api_base_url()
    "https://gitea-server.fly.dev/api/v1/"
  """
  @spec api_base_url() :: String.t()
  def api_base_url do
    "https://#{Envar.get("GITEA_URL")}/api/v1/"
  end

  @doc """
  `make_url/1` constructs the URL based on the supplied git `url`.

  ## Examples
    iex> Gitea.Helpers.make_url("gitea-server.fly.dev")
    "git@gitea-server.fly.dev:"

    iex> Gitea.Helpers.make_url("github.com")
    "git@github.com:"

  """
  @spec make_url(String.t()) :: String.t()
  def make_url(git_url), do: "git@#{git_url}:"

  @doc """
  `remote_url/3` returns the git remote url.
  """
  @spec remote_url(String.t(), String.t(), String.t()) :: String.t()
  def remote_url(base_url, org, repo) do
    "#{base_url}#{org}/#{repo}.git"
  end

  @doc """
  `remote_url_ssh/2` returns the remote ssh url for cloning.
  """
  @spec remote_url_ssh(String.t(), String.t()) :: String.t()
  def remote_url_ssh(org, repo) do
    url = Envar.get("GITEA_URL")
    git_url = make_url(url)
    remote_url(git_url, org, repo)
  end

  @doc """
  returns {org, repo} from git url
  ## Examples
    iex> Gitea.Helpers.get_org_repo_names("git@gitea-server.fly.dev:myorg/myrepo.git")
    {"myorg", "myrepo"}

    iex> Gitea.Helpers.get_org_repo_names("ssh://git@gitea-server.fly.dev:10022/theorg/myrepo.git")
    {"theorg", "myrepo"}

    iex> Gitea.Helpers.get_org_repo_names("https://gitea-server.fly.dev/myorg/public-repo.git")
    {"myorg", "public-repo"}
  """
  @spec get_org_repo_names(String.t()) :: {String.t(), String.t()}
  def get_org_repo_names(url) do
    if String.starts_with?(url, "git") do
      url
      |> String.split(":")
      |> List.last()
      |> Path.rootname()
      |> Path.split()
      |> List.to_tuple()
    else
      url
      |> Path.rootname()
      |> String.split("/")
      |> Enum.take(-2)
      |> List.to_tuple()
    end
  end

  @doc """
  `get_repo_name_from_url/1` extracts the repository name from a .git url.
  Feel free to refactor/simplify this function if you want.
  """
  @spec get_repo_name_from_url(String.t()) :: String.t()
  def get_repo_name_from_url(url) do
    {_org, repo} = get_org_repo_names(url)
    repo
  end

  @doc """
  `get_org_name_from_url/1` extracts the organisation name from a .git url.
  ssh://git@gitea-server.fly.dev:10022/theorg/myrepo.git
  """
  @spec get_org_name_from_url(String.t()) :: String.t()
  def get_org_name_from_url(url) do
    {org, _repo} = get_org_repo_names(url)
    org
  end

  @doc """
  Returns the full system path
  """
  @spec create_local_path(list(String.t())) :: binary()
  def create_local_path(path) do
    Path.join([temp_dir(git_dir()) | path]) |> Path.expand()
  end

  @doc """
  `local_repo_path/2` returns the full system path for the cloned repo
  on the `localhost` i.e. the Elixir/Phoenix server that cloned it.
  """
  @spec local_repo_path(String.t(), String.t()) :: binary()
  def local_repo_path(org, repo) do
    # coveralls-ignore-start
    if @mock do
      if String.contains?(repo, "no-repo") || String.contains?(repo, "error") do
        # in branch test we need to simulate a full path not a test-repo one ...
        Path.join([temp_dir(git_dir()), org, repo]) |> Path.expand()
      else
        Path.join([temp_dir(git_dir()), "test-repo"]) |> Path.expand()
      end
    else
      Path.join([temp_dir(git_dir()), org, repo]) |> Path.expand()
    end

    # coveralls-ignore-stop
  end

  @doc """
  `local_git_repo/2` returns the `%Git.Repository{}` (struct) for an `org` and `repo`
  on the `localhost`. This is used by the `Git` module to perform operations.
  """
  @spec local_git_repo(String.t(), String.t()) :: Git.Repository.t()
  def local_git_repo(org, repo) do
    %Git.Repository{path: local_repo_path(org, repo)}
  end

  @doc """
  `temp_dir/1` returns the Current Working Directory (CWD).
  Made this a function in case we want to change the location of the
  directory later e.g. to a temporary directory.
  """
  @spec temp_dir(any()) :: binary()
  def temp_dir(dir) when is_binary(dir) do
    if File.exists?(dir) do
      dir
    else
      File.cwd!()
    end
  end

  def temp_dir(_), do: File.cwd!()
end

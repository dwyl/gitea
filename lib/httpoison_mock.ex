defmodule Gitea.HTTPoisonMock do
  @moduledoc """
  Mock (stub) our API requests to the Gitea API
  so that we can test all of our code (with Mocks) on GitHub CI.
  These functions pattern match on the params
  and return the expected responses.
  If you know of a better way of doing this
  (preferably without introducing more dependencies ...)
  Please share:
  [github.com/dwyl/**gitea/issues**](https://github.com/dwyl/gitea/issues)
  """
  require Logger

  @remote_repo_create_response_body %{
    allow_rebase_explicit: true,
    stars_count: 0,
    internal: false,
    empty: false,
    ssh_url: "git@gitea-server.fly.dev:myorg/public-repo.git",
    mirror: false,
    avatar_url: "",
    mirror_updated: "0001-01-01T00:00:00Z",
    allow_merge_commits: true,
    repo_transfer: nil,
    allow_squash_merge: true,
    archived: false,
    parent: nil,
    name: "public-repo",
    has_wiki: true,
    release_counter: 0,
    private: false,
    forks_count: 0,
    has_pull_requests: true,
    open_pr_counter: 0,
    mirror_interval: "",
    has_projects: true,
    clone_url: "https://gitea-server.fly.dev/myorg/public-repo.git",
    template: false,
    fork: false,
    has_issues: true,
    full_name: "myorg/public-repo",
    website: "",
    ignore_whitespace_conflicts: false,
    original_url: "",
    html_url: "https://gitea-server.fly.dev/myorg/public-repo",
    open_issues_count: 0,
    default_merge_style: "merge",
    internal_tracker: %{
      allow_only_contributors_to_track_time: true,
      enable_issue_dependencies: true,
      enable_time_tracker: true
    },
    permissions: %{admin: true, pull: true, push: true},
    allow_rebase: true
  }

  # make a valid response body for testing
  def make_repo_create_post_response_body(repo_name) do
    Map.merge(@remote_repo_create_response_body, %{
      clone_url: "https://gitea-server.fly.dev/myorg/#{repo_name}.git",
      # description: repo_name,
      full_name: "myorg/#{repo_name}",
      html_url: "https://gitea-server.fly.dev/myorg/#{repo_name}",
      ssh_url: "git@gitea-server.fly.dev:myorg/#{repo_name}.git",
      # readme: repo_name,
      name: repo_name
    })
  end

  @raw_response {:ok,
                 %HTTPoison.Response{
                   body: "# public-repo\n\nplease don't update this. the tests read it.",
                   status_code: 200
                 }}

  @doc """
  `get/2` mocks the HTTPoison.get/2 function when parameters match test vars.
  Feel free refactor this if you can make it pretty.
  """
  def get(url, _headers) do
    Logger.debug("Gitea.HTTPoisonMock.get/2 #{url}")

    case String.contains?(url, "/raw/") do
      true ->
        @raw_response

      false ->
        repo_name = Gitea.Helpers.get_repo_name_from_url(url)

        response_body =
          make_repo_create_post_response_body(repo_name)
          |> Jason.encode!()

        {:ok, %HTTPoison.Response{body: response_body, status_code: 200}}
    end
  end

  @doc """
  `post/3` mocks the HTTPoison.post/3 function when parameters match test vars.
  Feel free refactor this if you can make it pretty.
  """
  def post(url, body, headers) do
    Logger.debug("Gitea.HTTPoisonMock.post/3 #{url}")

    cond do
      url =~ "markdown/raw" ->
        post_raw_html(url, body, headers)

      # create a specific case to similuate error when creating repository
      url =~ "/org/notfound" ->
        {:ok, %HTTPoison.Response{status_code: 422}}

      url =~ "/repo" ->
        body_map = Jason.decode!(body) |> Useful.atomize_map_keys()

        response_body =
          make_repo_create_post_response_body(body_map.name)
          |> Jason.encode!()

        {:ok, %HTTPoison.Response{body: response_body, status_code: 200}}

      url =~ "/orgs" ->
        {:ok, %HTTPoison.Response{body: Jason.encode!(%{username: "new_org"}), status_code: 200}}

      true ->
        {:ok, %HTTPoison.Response{body: Jason.encode!(""), status_code: 404}}
    end
  end

  def raw_html do
    "<h1 id=\"user-content-public-repo\">public-repo</h1>\n<p>please don&#39;t update this. the tests read it.</p>\n"
  end

  @doc """
  `post_raw/3` mocks the GiteaHttp.post_raw/3 function.
  Feel free refactor this if you can make it pretty.
  """
  def post_raw_html(url, _body, _headers) do
    Logger.debug("Gitea.HTTPoisonMock.post_raw/3 #{url}")
    response_body = raw_html()
    {:ok, %HTTPoison.Response{body: response_body, status_code: 200}}
  end

  @doc """
  `delete/1` mocks the HTTPoison `delete` function.
  Feel free refactor this if you can make it pretty.
  """
  def delete(url) do
    Logger.debug("Gitea.HTTPoisonMock.delete/1 #{url}")
    # check delete request endpooints
    # match delete org
    if url =~ "/orgs" do
      {:ok,
       %HTTPoison.Response{
         body: "",
         status_code: 204
       }}
    else
      {:ok,
       %HTTPoison.Response{
         body: Jason.encode!(%{deleted: List.first(String.split(url, "?"))}),
         status_code: 200
       }}
    end
  end
end

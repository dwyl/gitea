defmodule GiteaTest do
  use ExUnit.Case, async: true
  require Logger
  doctest Gitea
  # Let's do this!! 🚀
  @cwd File.cwd!()
  @git_dir Envar.get("GIT_TEMP_DIR_PATH", @cwd)
  @mock Application.compile_env(:gitea, :mock)

  # https://elixirforum.com/t/random-unisgned-64-bit-integers/31659
  # e.g: "43434105246416498"
  defp random_postive_int_str() do
    :crypto.strong_rand_bytes(7) |> :binary.decode_unsigned() |> Integer.to_string()
  end

  # Create a test repo with the name "test-repo123"
  defp test_repo() do
    "test-repo" <> random_postive_int_str()
  end

  defp create_test_git_repo(org_name) do
    repo_name = test_repo()
    Gitea.remote_repo_create(org_name, repo_name, false)
    git_repo_url = Gitea.Helpers.remote_url_ssh(org_name, repo_name)
    # Logger.debug("create_test_git_repo/1 git_repo_url: #{git_repo_url}")
    Gitea.clone(git_repo_url)

    repo_name
  end

  defp teardown_local_and_remote(org_name, repo_name) do
    Useful.empty_dir_contents(Envar.get("GIT_TEMP_DIR_PATH"))
    Gitea.remote_repo_delete(org_name, repo_name)
  end

  test "remote_org_create\2 create a new organistaion" do
    org_name = "new_org"

    params = %{
      username: "new_org",
      description: "org description",
      full_name: "new organisation",
      visibility: "public"
    }

    {:ok, response} = Gitea.remote_org_create(params)

    assert response.username
    # delete organisation to allow test to run again
    {:ok, response_delete} = Gitea.remote_org_delete(org_name)
    assert response_delete.status_code == 204
  end

  test "remote_repo_create/3 creates a new repo on the gitea server" do
    org_name = "myorg"
    repo_name = test_repo()
    {:ok, :repo_created} = Gitea.remote_repo_create(org_name, repo_name, false)

    # Cleanup:
    teardown_local_and_remote(org_name, repo_name)
  end

  test "remote_repo_create/3 fails to create repo when org not found" do
    org_name = "notfound"
    repo_name = "repo"
    assert {:error, %Gitea.Error{}} = Gitea.remote_repo_create(org_name, repo_name, false)

    # Cleanup:
    teardown_local_and_remote(org_name, repo_name)
  end

  test "Gitea.remote_read_raw/4 retrieves the contents of the README.md file" do
    org_name = "myorg"
    repo_name = "public-repo"
    file_name = "README.md"

    {:ok, %HTTPoison.Response{body: response_body}} =
      Gitea.remote_read_raw(org_name, repo_name, file_name)

    expected = "# public-repo\n\nplease don't update this. the tests read it."
    assert expected == response_body
  end

  test "Gitea.remote_render_markdown_html/4 renders README.md file as HTML!" do
    org_name = "myorg"
    repo_name = "public-repo"
    file_name = "README.md"

    {:ok, %HTTPoison.Response{body: response_body}} =
      Gitea.remote_render_markdown_html(org_name, repo_name, file_name)

    # IO.inspect(response_body)
    assert Gitea.HTTPoisonMock.raw_html() == response_body
  end

  test "Gitea.clone clones a known remote repository gitea on Fly.io" do
    org = "nelsonic"
    repo = "public-repo"
    # first delete if already exists:
    Useful.empty_dir_contents(@git_dir)

    # get url for cloning
    git_repo_url = Gitea.Helpers.remote_url_ssh(org, repo)

    # clone should work both in mock: true and mock: false
    assert {:ok, _path} = Gitea.clone(git_repo_url)
    # assert path == Gitea.Helpers.local_repo_path(repo)

    # Clean up (but don't delete the remote repo!!)
    Useful.empty_dir_contents(@git_dir)
  end

  test "Gitea.clone error (simulate unhappy path)" do
    repo = "error"
    org = "myorg"
    git_repo_url = Gitea.Helpers.remote_url_ssh(org, repo)
    assert {:error, %Gitea.Error{}} = Gitea.clone(git_repo_url)
  end

  test "Gitea.clone/2 clones a known remote repository gitea on Fly.io" do
    org = "nelsonic"
    repo = "public-repo"
    git_repo_url = Gitea.Helpers.remote_url_ssh(org, repo)

    assert {:ok, _path} = Gitea.clone(git_repo_url, ["nelsonic", "public-repo"])

    # Clean up (but don't delete the remote repo!!)
    Useful.empty_dir_contents(@git_dir)
  end

  test "Gitea.clone/2 error" do
    repo = "error"
    org = "myorg"
    git_repo_url = Gitea.Helpers.remote_url_ssh(org, repo)
    assert {:error, %Gitea.Error{}} = Gitea.clone(git_repo_url, ["error", "myorg"])
  end

  test "local_branch_create/1 creates a new branch on the localhost" do
    org_name = "myorg"
    repo_name = create_test_git_repo(org_name)
    # delete draft branch if exists:
    {:ok, branch_name} = Git.branch(%Git.Repository{path: @cwd}, ~w(--show-current))
    Git.branch(Gitea.Helpers.local_git_repo(org_name, repo_name), ~w(-D draft))

    {:ok, res} = Gitea.local_branch_create(org_name, repo_name, "draft")
    assert res == "Switched to a new branch 'draft'\n"

    # Cleanup!
    branch_name = String.replace(branch_name, "\n", "")
    Git.checkout(%Git.Repository{path: @cwd}, [branch_name])
    Git.branch(Gitea.Helpers.local_git_repo(org_name, repo_name), ~w(-D draft))
    teardown_local_and_remote(org_name, repo_name)
  end

  test "local_branch_create/2 returns error if repo doesn't exist" do
    repo_name = "no-repo-" <> random_postive_int_str()
    org_name = "no-org-" <> random_postive_int_str()
    {:error, error} = Gitea.local_branch_create(org_name, repo_name, "draft")
    # Unfortunately the error message depends on Git version,
    # so we cannot assert the contents of the error message.
    # but we know from the pattern match above that it did error.
    Logger.error("test: local_branch_create/1 > error: #{error}")
  end

  test "write_text_to_file/3 writes text to a specified file" do
    org_name = "myorg"
    repo_name = create_test_git_repo(org_name)
    file_name = "README.md"
    text = "text #{repo_name}"

    assert {:ok, _path} = Gitea.local_file_write_text(org_name, repo_name, file_name, text)

    # Confirm the text was written to the file:
    assert {:ok, text} == Gitea.local_file_read(org_name, repo_name, file_name)

    # Cleanup!
    teardown_local_and_remote(org_name, repo_name)
  end

  test "write to non existing directory return error" do
    assert {:error, %Gitea.Error{}} =
             Gitea.local_file_write_text("wrongorg", "no-repo", "wrongfile.text", "test fail")
  end

  test "commit/3 creates a commit in the repo" do
    org_name = "myorg"
    repo_name = create_test_git_repo(org_name)
    file_name = "README.md"

    assert {:ok, _path} =
             Gitea.local_file_write_text(org_name, repo_name, file_name, "text #{repo_name}")

    # Confirm the text was written to the file:
    file_path = Path.join([Gitea.Helpers.local_repo_path(org_name, repo_name), file_name])
    assert {:ok, "text #{repo_name}"} == File.read(file_path)

    {:ok, msg} =
      Gitea.commit(org_name, repo_name, %{
        message: "test msg",
        full_name: "Al Ex",
        email: "c@t.co"
      })

    assert String.contains?(msg, "test msg")
    assert String.contains?(msg, "1 file changed, 1 insertion(+)")

    # Cleanup!
    teardown_local_and_remote(org_name, repo_name)
  end

  test "commit/3 fails when author is not defined" do
    assert {:error, _msg} =
             Gitea.commit("notfound", "error-repo", %{
               message: "test fail commit",
               full_name: "",
               email: ""
             })
  end

  test "Gitea.push/2 pushes the commit to the remote repo" do
    org_name = "myorg"
    repo_name = create_test_git_repo(org_name)
    file_name = "README.md"
    text = "text #{repo_name}"

    assert {:ok, _path} = Gitea.local_file_write_text(org_name, repo_name, file_name, text)

    # Confirm the text was written to the file:
    file_path = Path.join([Gitea.Helpers.local_repo_path(org_name, repo_name), file_name])
    assert {:ok, "text #{repo_name}"} == File.read(file_path)

    # Commit the updated text:
    {:ok, msg} =
      Gitea.commit(org_name, repo_name, %{
        message: "test msg",
        full_name: "Al Ex",
        email: "c@t.co"
      })

    assert String.contains?(msg, "test msg")

    #  Push to gitea Server!
    Gitea.push(org_name, repo_name)

    # Confirm the README.md of the newly created repo was updated:
    {:ok, %HTTPoison.Response{body: response_body}} =
      Gitea.remote_read_raw(org_name, repo_name, file_name)

    if @mock do
      assert response_body ==
               "# public-repo\n\nplease don't update this. the tests read it."
    else
      assert response_body == text
    end

    # Cleanup!
    teardown_local_and_remote(org_name, repo_name)
  end
end

defmodule GiteaApiTest do
  use ExUnit.Case
  alias Gitea.API, as: API
  doctest Gitea

  test "create remote repository" do
    API.create_repo("githubci", "new_repo", [])

    API.delete_repo("githubci", "new_repo")

    assert true
  end

  test "create org" do
    API.create_org("test-org") |> IO.inspect()
  end
end

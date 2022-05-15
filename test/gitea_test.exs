defmodule GiteaTest do
  use ExUnit.Case
  doctest Gitea

  test "clone repository error" do
    assert {:error, _err} = Gitea.clone("https://gitea-server.fly.dev/nope/nope")
  end
end

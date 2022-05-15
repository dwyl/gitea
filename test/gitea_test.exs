defmodule GiteaTest do
  use ExUnit.Case
  doctest Gitea

  test "greets the world" do
    assert Gitea.hello() == :world
  end
end

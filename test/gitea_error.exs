defmodule GiteaErrorTest do
  use ExUnit.Case, async: true

  test "Gitea error raised using Gitea.Error struct" do
    assert_raise Gitea.Error, fn ->
      raise %Gitea.Error{message: "gitea error", reason: :test_error}
    end
  end

  test "Gitea error raised using arguments" do
    assert_raise Gitea.Error, fn ->
      raise Gitea.Error, message: "oop", reason: :test_error
    end
  end

  test "Error message is defined in Gitea.Error" do
    err = %Gitea.Error{message: "A message to you Rudy", reason: :rudy_error}
    assert Exception.message(err) == "A message to you Rudy, reason: rudy_error"
  end
end

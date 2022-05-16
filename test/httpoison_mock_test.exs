defmodule HttPoisonMockTest do
  use ExUnit.Case, async: true
  # Mock function tests that work both when mock: true and false!

  test "gitea.HTTPoisonMock.get /raw/ returns 200" do
    {:ok, %HTTPoison.Response{status_code: status}} =
      gitea.HTTPoisonMock.get("/raw/", "any-header")

    assert status == 200
  end

  test "gitea.HTTPoisonMock.get any url should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status}} =
      gitea.HTTPoisonMock.get("org/any", "any-header")

    assert status == 200
  end

  test "gitea.HTTPoisonMock.post any url should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status, body: resp_body}} =
      gitea.HTTPoisonMock.post("hi", Jason.encode!(%{name: "simon"}), "any-header")

    assert status == 200
    body_map = Jason.decode!(resp_body) |> Useful.atomize_map_keys()
    assert body_map.full_name == "myorg/simon"
  end

  test "gitea.HTTPoisonMock.delete any url should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status}} = gitea.HTTPoisonMock.delete("any?url")
    assert status == 200
  end

  test "gitea.HTTPoisonMock.post when url is markdown/raw should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      gitea.HTTPoisonMock.post("markdown/raw", "any", "any")
    assert status == 200
    assert body == gitea.HTTPoisonMock.raw_html()
  end
end

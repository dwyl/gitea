defmodule HttPoisonMockTest do
  use ExUnit.Case, async: true
  # Mock function tests that work both when mock: true and false!

  test "Gitea.HTTPoisonMock.get /raw/ returns 200" do
    {:ok, %HTTPoison.Response{status_code: status}} =
      Gitea.HTTPoisonMock.get("/raw/", "any-header")

    assert status == 200
  end

  test "Gitea.HTTPoisonMock.get any url should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status}} =
      Gitea.HTTPoisonMock.get("org/any", "any-header")

    assert status == 200
  end

  test "Gitea.HTTPoisonMock.post /repos/org_name should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status, body: resp_body}} =
      Gitea.HTTPoisonMock.post("/repos/myorg", Jason.encode!(%{name: "simon"}), "any-header")

    assert status == 200
    body_map = Jason.decode!(resp_body) |> Useful.atomize_map_keys()
    assert body_map.full_name == "myorg/simon"
  end

  test "Gitea.HTTPoisonMock.delete any url should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status}} = Gitea.HTTPoisonMock.delete("any?url")
    assert status == 200
  end

  test "Gitea.HTTPoisonMock.post when url is markdown/raw should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      Gitea.HTTPoisonMock.post("markdown/raw", "any", "any")

    assert status == 200
    assert body == Gitea.HTTPoisonMock.raw_html()
  end

  test "Gitea.HTTPoisonMock.post when url is not supported should return status 404" do
    {:ok, %HTTPoison.Response{status_code: status}} =
      Gitea.HTTPoisonMock.post("/not-defined", "any", "any")

    assert status == 404
  end
end

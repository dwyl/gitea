defmodule Gitea.API do
  @moduledoc """
  Helper functions for Gitea API
  """

  defp api_base_url() do
    server_url = Application.get_env(:gitea, :gitea_server_url)
    "https://#{server_url}/api/v1/"
  end

  def create_repo(org_name, repo_name, opts \\ []) do
    url = api_base_url() <> "org/#{org_name}/repos"
    token = Application.get_env(:gitea, :gitea_access_token)

    json = %{
      name: opts[:repo_name] || repo_name,
      private: opts[:private] || false,
      description: opts[:desc] || repo_name,
      readme: opts[:readme] || repo_name
    }

    headers = [
      {"Authorization", "token #{token}"},
      {"Accept", "application/json"}
    ]

    case Req.build(:post, url, headers: headers, body: {:json, json})
         |> Req.encode_body()
         |> Req.run() do
      {:ok, _response} -> {:ok, "Repository created"}
      {:error, _reason} -> {:error, "Couldn't create repository"}
    end
  end

  def delete_repo(org_name, repo_name) do
    url = api_base_url() <> "repos/#{org_name}/#{repo_name}"
    token = Application.get_env(:gitea, :gitea_access_token)

    headers = [
      {"Authorization", "token #{token}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]

    case Req.build(:delete, url, headers: headers)
         |> Req.run() do
      {:ok, response} -> {:ok, response}
      {:error, _reason} -> {:error, "Couldn't delete repository"}
    end
  end
end

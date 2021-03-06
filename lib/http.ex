defmodule Gitea.Http do
  @moduledoc """
  Documentation for the `HTTP` "verb" functions.
  Should be self-explanatory.
  Each function documented & typespecd.
  If anything is unclear, please open an issue:
  [github.com/dwyl/**gitea/issues**](https://github.com/dwyl/gitea/issues)
  """
  require Logger

  @mock Application.compile_env(:gitea, :mock)
  Logger.debug("GiteaHttp > config :gitea, mock: #{to_string(@mock)}")
  @httpoison (@mock && Gitea.HTTPoisonMock) || HTTPoison

  defp access_token do
    Envar.get("GITEA_ACCESS_TOKEN")
  end

  defp auth_header do
    {"Authorization", "token #{access_token()}"}
  end

  defp json_headers do
    [
      {"Accept", "application/json"},
      auth_header(),
      {"Content-Type", "application/json"}
    ]
  end

  @doc """
  `inject_poison/0` injects a TestDouble of HTTPoison in Test.
  see: https://github.com/dwyl/elixir-auth-google/issues/35
  """
  def inject_poison, do: @httpoison

  @doc """
  `parse_body_response/1` parses the response returned by the Gitea Server
  so your app can use the resulting JSON.
  """
  @spec parse_body_response({atom, String.t()} | {:error, any}) :: {:ok, map} | {:error, any}
  def parse_body_response({:error, err}), do: {:error, err}
  # Deleting a repository or an organisation returns an empty string for the body value
  # Instead of returning {:error, :no_body) (see next parse_body_response definition) 
  # the function returns {:ok, response} when the status code response is 204
  # see https://github.com/dwyl/gitea/pull/8#discussion_r874618485
  def parse_body_response({:ok, response = %{status_code: 204}}), do: {:ok, response}

  # Successful status are in 200..299, see https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
  def parse_body_response({:ok, %{status_code: status_code}}) when status_code not in 200..299,
    do: {:error, status_code}

  def parse_body_response({:ok, response}) do
    body = Map.get(response, :body)

    if body == nil || byte_size(body) == 0 do
      Logger.warning("GiteaHttp.parse_body_response: response body is nil!")
      {:error, :no_body}
    else
      {:ok, str_key_map} = Jason.decode(body)
      # make keys of map atoms for easier access in templates etc.
      {:ok, Useful.atomize_map_keys(str_key_map)}
    end
  end

  @doc """
  `get/1` accepts one argument: `url` the REST API endpoint.
  Makes an `HTTP GET` request to the specified `url`.
  Auth Headers and Content-Type are implicit.
  returns `{:ok, map}`
  """
  @spec get(String.t()) :: {:ok, map} | {:error, any}
  def get(url) do
    Logger.debug("GiteaHttp.get #{url}")

    inject_poison().get(url, json_headers())
    |> parse_body_response()
  end

  @doc """
  `get_raw/1` as it's name suggests gets the raw data
  (expects the reponse to be plaintext not JSON)
  accepts one argument: `url` the REST API endpoint.
  Makes an `HTTP GET` request to the specified `url`.
  Auth Headers and Content-Type are implicit.
  returns `{:ok, map}`
  """
  @spec get_raw(String.t()) :: {:ok, map} | {:error, any}
  def get_raw(url) do
    Logger.debug("GiteaHttp.get_raw #{url}")
    inject_poison().get(url, [auth_header()])
  end

  @doc """
  `post_raw_html/2` accepts two arguments: `url` and `raw_markdown`.
  Makes an `HTTP POST` request to the specified `url`
  passing in the `params` as the request body.
  Does NOT attempt to parse the response body as JSON.
  Auth Headers and Content-Type are implicit.
  """
  @spec post_raw_html(String.t(), String.t()) :: {:ok, String.t()} | {:error, any}
  def post_raw_html(url, raw_markdown) do
    Logger.debug("GiteaHttp.post_raw #{url}")
    # Logger.debug("raw_markdown: #{raw_markdown}")
    headers = [
      {"Accept", "text/html"},
      auth_header()
    ]

    inject_poison().post(url, raw_markdown, headers)
  end

  @doc """
  `post/2` accepts two arguments: `url` and `params`.
  Makes an `HTTP POST` request to the specified `url`
  passing in the `params` as the request body.
  Auth Headers and Content-Type are implicit.
  """
  @spec post(String.t(), map) :: {:ok, map} | {:error, any}
  def post(url, params \\ %{}) do
    Logger.debug("GiteaHttp.post #{url}")
    body = Jason.encode!(params)

    inject_poison().post(url, body, json_headers())
    |> parse_body_response()
  end

  @doc """
  `delete/1` accepts a single argument `url`;
  the `url` for the repository to be deleted.
  """
  @spec delete(String.t()) :: {:ok, map} | {:error, any}
  def delete(url) do
    Logger.debug("GiteaHttp.delete #{url}")

    inject_poison().delete(url <> "?token=#{access_token()}")
    |> parse_body_response()
  end
end

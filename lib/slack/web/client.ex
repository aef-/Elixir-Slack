defmodule Slack.Web.Client do
  @moduledoc """
  Default http client used for all requests to Slack Web API.

  All Slack RPC method calls are delivered via post.

  Parsed body data is returned unwrapped to the caller.
  """

  def post!(url, body) do
    Tesla.post!(client(), url, body)
    |> Map.fetch!(:body)
    |> Jason.decode!(keys: :atoms)
    |> case do
      %{ok: false, error: error} ->
        raise Module.concat(Slack.Web.Errors, Macro.camelize(error))

      body ->
        body
    end
  end

  def post(url, body) do
    with {:ok, %Tesla.Env{body: body}} <- Tesla.post(client(), url, body),
         {:ok, %{ok: true} = body} <- Jason.decode(body, keys: :atoms) do
      {:ok, body}
    else
      {:ok, %{error: error}} ->
        {:error, error}

      error ->
        error
    end
  end

  defp client() do
    [
      Tesla.Middleware.FormUrlencoded
    ]
    |> Tesla.client()
  end
end

defmodule Slack.Web.Client do
  @moduledoc """
  Default http client used for all requests to Slack Web API.

  All Slack RPC method calls are delivered via post.

  Parsed body data is returned unwrapped to the caller.
  """

  def post!(url, body) do
    Tesla.post!(client(), url, body)
    |> Map.fetch!(:body)
  end

  def post(url, body) do
    with {:ok, tesla} <- Tesla.post(client(), url, body),
         {:ok, body} <- Map.fetch(tesla, :body) do
      {:ok, body}
    end
  end

  defp client() do
    [
      {Tesla.Middleware.JSON, engine: Jason, engine_opts: [keys: :atoms]},
      Tesla.Middleware.FormUrlencoded
    ]
    |> Tesla.client()
  end
end

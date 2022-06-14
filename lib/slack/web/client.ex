defmodule Slack.Web.Client do
  @moduledoc """
  Default http client used for all requests to Slack Web API.

  All Slack RPC method calls are delivered via post.

  Parsed body data is returned unwrapped to the caller.
  """

  use Tesla

  plug(Tesla.Middleware.FormUrlencoded)
  plug(Tesla.Middleware.JSON, engine: Jason, engine_opts: [keys: :atoms])

  @impl true
  def post!(url, body) do
    url
    |> post!(body)
    |> Map.fetch!(:body)
  end

  @impl true
  def post(url, body) do
    with {:ok, tesla} <- post(url, body),
         {:ok, body} <- Map.fetch(tesla, :body) do
      {:ok, body}
    end
  end
end

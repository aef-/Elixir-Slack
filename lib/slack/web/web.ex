defmodule Slack.Web do
  @moduledoc false

  def get_documentation do
    File.ls!("#{__DIR__}/docs")
    |> format_documentation
  end

  defp format_documentation(files) do
    Enum.reduce(files, %{}, fn file, module_names ->
      json =
        File.read!("#{__DIR__}/docs/#{file}")
        |> Jason.decode!(%{})

      doc = Slack.Web.Documentation.new(json, file)

      module_names
      |> Map.put_new(doc.module, [])
      |> update_in([doc.module], &(&1 ++ [doc]))
    end)
  end
end

alias Slack.Web.Documentation

Enum.each(Slack.Web.get_documentation(), fn {module_name, functions} ->
  module =
    module_name
    |> String.split(".")
    |> Enum.map(&Macro.camelize/1)
    |> Enum.reduce(Slack.Web, &Module.concat(&2, &1))

  defmodule module do
    Enum.each(functions, fn doc ->
      function_name = doc.function

      arguments = Documentation.arguments(doc)
      argument_value_keyword_list = Documentation.arguments_with_values(doc)

      errors = Map.get(doc, :errors, [])

      errors =
        if is_nil(errors) do
          []
        else
          errors
        end

      Enum.each(errors, fn {name, message} ->
        error_module = Module.concat(Slack.Web.Errors, Macro.camelize(name))

        unless function_exported?(error_module, :__info__, 1) do
          defmodule error_module do
            defexception message: message
          end
        end
      end)

      @doc """
      #{Documentation.to_doc_string(doc)}
      """
      def unquote(:"#{function_name}!")(unquote_splicing(arguments), optional_params \\ %{}) do
        required_params = unquote(argument_value_keyword_list)

        params = build_params(required_params, optional_params)

        perform!(
          "#{url()}/api/#{unquote(doc.endpoint)}",
          params(unquote(function_name), params, unquote(arguments))
        )
      end

      @doc """
      #{Documentation.to_doc_string(doc)}
      """
      def unquote(function_name)(unquote_splicing(arguments), optional_params \\ %{}) do
        required_params = unquote(argument_value_keyword_list)

        params =
          optional_params
          |> Map.to_list()
          |> Keyword.merge(required_params)
          |> Keyword.put_new(:token, get_token(optional_params))
          |> Enum.reject(fn {_, v} -> v == nil end)

        perform(
          "#{url()}/api/#{unquote(doc.endpoint)}",
          params(unquote(function_name), params, unquote(arguments))
        )
      end
    end)

    defp url, do: Application.get_env(:slack, :url, "https://slack.com")

    defp perform!(url, body) do
      Slack.Web.Client.post!(url, body)
    end

    defp perform(url, body) do
      Slack.Web.Client.post(url, body)
    end

    defp get_token(%{token: token}), do: token
    defp get_token(_), do: Application.get_env(:slack, :api_token)

    defp build_params(required_params, optional_params) do
      optional_params
      |> Map.to_list()
      |> Keyword.merge(required_params)
      |> Keyword.put_new(:token, get_token(optional_params))
      |> Enum.reject(fn {_, v} -> v == nil end)
    end

    defp params(:upload, params, arguments) do
      file = List.first(arguments)

      params =
        Enum.map(params, fn {key, value} ->
          {"", to_string(value), {"form-data", [{"name", key}]}, []}
        end)

      {:multipart, params ++ [{:file, file, []}]}
    end

    defp params(_, params, _), do: params
  end
end)

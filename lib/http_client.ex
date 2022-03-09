  defmodule Crawler.HttpClient do
    def get(url) do
      url
      |> IO.inspect()
      |> HTTPoison.get()
      |> case do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          body

        _ ->
          []
      end
    end
  end

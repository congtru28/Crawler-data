defmodule Crawler.HttpClient do
  def get(url) do
    IO.inspect(url)
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        _ -> []
    end
  end
end
